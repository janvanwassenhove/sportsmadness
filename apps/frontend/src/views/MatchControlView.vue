<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { supabase } from '@/lib/supabase'
import { soundManager, SoundManager } from '@/lib/soundManager'
import type { 
  TimelineEvent, 
  GoalEvent, 
  BoosterActivatedEvent, 
  MaddieActivatedEvent, 
  CardIssuedEvent,
  MatchStatusEvent,
  PenaltyCornerEvent
} from '@/types/timeline'
import { createTimelineEvent, addTimelineEvent, getEventsByType, getEventsByTeam } from '@/types/timeline'

interface Props {
  id: string
}

interface PlayerPenalty {
  type: 'yellow' | 'green' | 'red'
  expires_at: string
  time_remaining?: number
}

interface Player {
  name: string
  number: string | number
  position: string
}

interface Booster {
  id: string
  name: string
  description: string
  icon: string
  duration?: number // in minutes, undefined for instant effects
}

interface TeamBooster {
  booster: Booster
  assignedAt: string
  used: boolean
}

const props = defineProps<Props>()
const router = useRouter()
const { t } = useI18n()

const match = ref<any>(null)
const teams = ref<Record<string, any>>({})
const loading = ref(true)
const resetting = ref(false)
const initializing = ref(false)
const initialized = ref(false)
const timer = ref<number | null>(null)
const penaltyTimer = ref<number | null>(null)

// UI state management
const updatingMatch = ref(false)
const buttonStates = ref({
  play: false,
  pause: false,
  finish: false,
  spinners: false
})

// Watchdog timers to prevent stuck button states
const buttonWatchdogTimers = ref<Record<string, number>>({})

// Function to set button state with automatic timeout protection
function setButtonState(button: 'play' | 'pause' | 'finish' | 'spinners', state: boolean) {
  buttonStates.value[button] = state
  
  // Clear existing watchdog timer
  if (buttonWatchdogTimers.value[button]) {
    clearTimeout(buttonWatchdogTimers.value[button])
    delete buttonWatchdogTimers.value[button]
  }
  
  // If setting to true, create a watchdog timer to auto-reset after 15 seconds
  if (state === true) {
    buttonWatchdogTimers.value[button] = setTimeout(() => {
      console.warn(`⚠️ Button state '${button}' was stuck - auto-resetting`)
      buttonStates.value[button] = false
      delete buttonWatchdogTimers.value[button]
    }, 15000) as unknown as number
  }
}

// Score update debouncing
const scoreUpdateTimeouts = ref<Record<string, number>>({})

// PC update debouncing
const pcUpdateTimeouts = ref<Record<string, number>>({})

// Match phase tracking
const currentPhase = ref<'quarter' | 'break' | 'halftime' | 'finished'>('quarter')
const currentPeriod = ref(1) // Current quarter/half number
const phaseTimeLeft = ref(0) // Time left in current phase
const totalMatchTime = ref(0) // Total match time in seconds

// Stats dialog state
const showStatsDialog = ref(false)
const statsFilterType = ref<string>('all')
const statsFilterTeam = ref<string>('all')

// Booster selection state
const showBoosterSelection = ref(false)
const isSpinning = ref(false)
const currentTeamSpinning = ref<'A' | 'B' | null>(null)
const spinningSlot = ref(0)
const selectedBoosters = ref<{ teamA: Booster[], teamB: Booster[] }>({ teamA: [], teamB: [] })

// Add a single canonical type for booster phases
type BoosterPhase =
  | 'ready'
  | 'team-a-first'
  | 'team-a-second'
  | 'team-b-first'
  | 'team-b-second'
  | 'complete'

// Use it when declaring the ref
const boosterPhase = ref<BoosterPhase>('ready')

const autoConfirmationPending = ref(false)

// Available boosters and maddies from database
const availableBoosters = ref<Booster[]>([])
const availableMaddies = ref<any[]>([])

// Active booster timers
const activeBoosterTimers = ref<Record<string, {
  booster: any
  team: 'a' | 'b'
  endTime: number
  intervalId: number
  oneSecondWarningPlayed: boolean
}>>({})

// Active maddie timer
const activeMaddieTimer = ref<{
  maddie: any
  endTime: number
  remainingTime: number
  intervalId?: number
} | null>(null)

// Update queue to prevent race conditions
const updateQueue: Array<() => Promise<any>> = []
let isProcessingQueue = false

// Load boosters and maddies from database
async function loadBoostersAndMaddies() {
  try {
    const [boostersResult, maddiesResult] = await Promise.all([
      supabase.from('boosters').select('*').order('title'),
      supabase.from('maddies').select('*').order('title')
    ])

    if (boostersResult.error) {
      console.error('Error loading boosters:', boostersResult.error)
    } else {
      // Transform database format to match existing interface
      availableBoosters.value = boostersResult.data.map(booster => ({
        id: booster.id,
        name: booster.title,
        description: booster.description,
        icon: booster.icon || '⚡',
        sound_file: booster.sound_file,
        duration: booster.has_countdown ? (booster.duration / 60) : undefined // Convert seconds to minutes, only if countdown enabled
      }))
    }

    if (maddiesResult.error) {
      console.error('Error loading maddies:', maddiesResult.error)
    } else {
      availableMaddies.value = maddiesResult.data
    }
  } catch (error) {
    console.error('Error loading boosters and maddies:', error)
  }
}

// Helper functions
const getOrdinalSuffix = (num: number): string => {
  const j = num % 10
  const k = num % 100
  if (j === 1 && k !== 11) return 'st'
  if (j === 2 && k !== 12) return 'nd'
  if (j === 3 && k !== 13) return 'rd'
  return 'th'
}

const teamA = computed(() => match.value ? teams.value[match.value.team_a] : null)
const teamB = computed(() => match.value ? teams.value[match.value.team_b] : null)

// Match settings computed properties
const matchSettings = computed(() => {
  if (!match.value) return null
  
  return {
    quarters_count: match.value.quarters_count || 4,
    quarter_duration_minutes: match.value.quarter_duration_minutes || 15,
    break_duration_minutes: match.value.break_duration_minutes || 2,
    halftime_duration_minutes: match.value.halftime_duration_minutes || 10
  }
})

const isHalfTimeGame = computed(() => {
  return matchSettings.value?.quarters_count === 2
})

const isSingleQuarterGame = computed(() => {
  return matchSettings.value?.quarters_count === 1
})

const currentPhaseLabel = computed(() => {
  if (!matchSettings.value) return 'Game'
  
  switch (currentPhase.value) {
    case 'quarter':
      if (isSingleQuarterGame.value) {
        return 'Match'
      } else if (isHalfTimeGame.value) {
        return `${currentPeriod.value}${currentPeriod.value === 1 ? 'st' : 'nd'} Half`
      } else {
        return `${currentPeriod.value}${getOrdinalSuffix(currentPeriod.value)} Quarter`
      }
    case 'break':
      return isHalfTimeGame.value ? 'Halftime' : 'Break'
    case 'halftime':
      return 'Halftime'
    case 'finished':
      return 'Game Over'
    default:
      return 'Game'
  }
})

const getPlayerPenalty = (team: 'a' | 'b', player: Player) => {
  if (!match.value?.cards?.player_penalties) return null
  
  const playerId = `${player.number}_${player.name.replace(/\s+/g, '_')}`
  const teamKey = `team_${team}`
  const penalty = match.value.cards.player_penalties[teamKey]?.[playerId]
  
  if (!penalty) return null
  
  if (penalty.expires_at === 'never') {
    return { ...penalty, time_remaining: 'Game' }
  }
  
  const now = new Date()
  const expiresAt = new Date(penalty.expires_at)
  const timeRemaining = Math.max(0, Math.floor((expiresAt.getTime() - now.getTime()) / 1000))
  
  return timeRemaining > 0 ? { ...penalty, time_remaining: timeRemaining } : null
}

const formatPenaltyTime = (seconds: number | string): string => {
  if (seconds === 'Game') return 'GAME'
  if (typeof seconds !== 'number') return ''
  
  const mins = Math.floor(seconds / 60)
  const secs = seconds % 60
  return `${mins}:${secs.toString().padStart(2, '0')}`
}

const getCurrentSlotIcon = () => {
  const index = spinningSlot.value
  return index !== undefined && availableBoosters.value[index] ? availableBoosters.value[index].icon : '🎰'
}

const getPhaseDescription = () => {
  switch (boosterPhase.value) {
    case 'ready':
      return 'Ready to select boosters'
    case 'team-a-first':
      return `${teamA.value?.name || 'Team A'} - First Booster`
    case 'team-a-second':
      return `${teamA.value?.name || 'Team A'} - Second Booster`
    case 'team-b-first':
      return `${teamB.value?.name || 'Team B'} - First Booster`
    case 'team-b-second':
      return `${teamB.value?.name || 'Team B'} - Second Booster`
    case 'complete':
      return 'All boosters selected!'
    default:
      return ''
  }
}

const getSpinButtonText = () => {
  switch (boosterPhase.value) {
    case 'ready':
      return '🎰 Start Booster Selection'
    case 'team-a-first':
    case 'team-a-second':
    case 'team-b-first':
    case 'team-b-second':
      return '🎰 Spin for Next Booster'
    default:
      return '🎰 Spin'
  }
}

const getActivePenaltiesForTeam = (team: 'a' | 'b'): Array<{
  playerId: string
  playerNumber: string | number
  playerName: string
  type: 'yellow' | 'green' | 'red'
  timeRemaining: string
}> => {
  if (!match.value?.cards?.player_penalties) return []
  
  const teamKey = `team_${team}`
  const penalties: Array<{
    playerId: string
    playerNumber: string | number
    playerName: string
    type: 'yellow' | 'green' | 'red'
    timeRemaining: string
  }> = []
  const teamPenalties = match.value.cards.player_penalties[teamKey] || {}
  const playerInfo = match.value.cards.player_info?.[teamKey] || {}
  
  Object.keys(teamPenalties).forEach(playerId => {
    const penalty = teamPenalties[playerId]
    const info = playerInfo[playerId]
    
    if (!penalty || !info) return
    
    let timeRemaining = 'GAME'
    if (penalty.expires_at !== 'never') {
      const now = new Date()
      const expiresAt = new Date(penalty.expires_at)
      const seconds = Math.max(0, Math.floor((expiresAt.getTime() - now.getTime()) / 1000))
      
      if (seconds > 0) {
        timeRemaining = formatPenaltyTime(seconds)
      } else {
        return // Penalty expired, don't include
      }
    }
    
    penalties.push({
      playerId,
      playerNumber: info.number,
      playerName: info.name,
      type: penalty.type,
      timeRemaining
    })
  })
  
  return penalties
}

const formatTime = (seconds: number) => {
  const mins = Math.floor(seconds / 60)
  const secs = seconds % 60
  return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
}

// Stats computed properties
const teamAStats = computed(() => {
  if (!match.value || !teamA.value) return null
  
  const timeline = match.value.timeline || []
  
  return {
    goals: getEventsByType(timeline, 'goal').filter(e => e.team === 'a').length,
    penaltyCorners: getEventsByType(timeline, 'penalty_corner').filter(e => e.team === 'a').length,
    boosters: getEventsByType(timeline, 'booster_activated').filter(e => e.team === 'a').length,
    maddies: getEventsByType(timeline, 'maddie_activated').length,
    yellowCards: getEventsByType(timeline, 'card_issued').filter(e => e.team === 'a' && (e as CardIssuedEvent).details.card_type === 'yellow').length,
    greenCards: getEventsByType(timeline, 'card_issued').filter(e => e.team === 'a' && (e as CardIssuedEvent).details.card_type === 'green').length,
    redCards: getEventsByType(timeline, 'card_issued').filter(e => e.team === 'a' && (e as CardIssuedEvent).details.card_type === 'red').length
  }
})

const teamBStats = computed(() => {
  if (!match.value || !teamB.value) return null
  
  const timeline = match.value.timeline || []
  
  return {
    goals: getEventsByType(timeline, 'goal').filter(e => e.team === 'b').length,
    penaltyCorners: getEventsByType(timeline, 'penalty_corner').filter(e => e.team === 'b').length,
    boosters: getEventsByType(timeline, 'booster_activated').filter(e => e.team === 'b').length,
    maddies: getEventsByType(timeline, 'maddie_activated').length,
    yellowCards: getEventsByType(timeline, 'card_issued').filter(e => e.team === 'b' && (e as CardIssuedEvent).details.card_type === 'yellow').length,
    greenCards: getEventsByType(timeline, 'card_issued').filter(e => e.team === 'b' && (e as CardIssuedEvent).details.card_type === 'green').length,
    redCards: getEventsByType(timeline, 'card_issued').filter(e => e.team === 'b' && (e as CardIssuedEvent).details.card_type === 'red').length
  }
})

const filteredTimeline = computed(() => {
  if (!match.value) return []
  
  let timeline = match.value.timeline || []
  
  // Filter by event type
  if (statsFilterType.value !== 'all') {
    timeline = getEventsByType(timeline, statsFilterType.value as TimelineEvent['type'])
  }
  
  // Filter by team
  if (statsFilterTeam.value !== 'all') {
    timeline = getEventsByTeam(timeline, statsFilterTeam.value as 'a' | 'b')
  }
  
  return timeline
})

// Timeline event recording helper
async function recordTimelineEvent(event: TimelineEvent) {
  if (!match.value) return
  
  try {
    const currentTimeline: TimelineEvent[] = match.value.timeline || []
    const updatedTimeline = addTimelineEvent(currentTimeline, event)
    
    console.log('📝 Recording timeline event:', event.type, event)
    
    await updateMatch({ timeline: updatedTimeline })
  } catch (error) {
    console.error('❌ Failed to record timeline event:', error)
    // Don't throw - timeline is non-critical
  }
}

async function loadMatch() {
  try {
    console.log('� Loading match with id:', props.id)
    const { data, error } = await supabase
      .from('matches')
      .select('*')
      .eq('id', props.id)
      .single()

    if (error) {
      console.error('Error loading match:', error)
      router.push('/admin')
      return
    }

    match.value = data
    console.log('� Match loaded:', { status: data.status, data })
    console.log('🚨 MATCH CONTROL - Now watching match:', data.id)
    
    // Check if match is already initialized
    // A match is considered initialized if it's not in pending state OR if it has meaningful modifications
    const hasConfirmedBoosters = (
      data.boosters?.teamA?.length > 0 || 
      data.boosters?.teamB?.length > 0
    )
    const hasCards = Object.keys(data.cards || {}).length > 0
    const hasScores = data.score_a > 0 || data.score_b > 0
    const hasModifiedTime = data.time_left !== getCalculatedMatchTime()
    const isNotPending = data.status !== 'pending'
    
    const hasBeenModified = isNotPending || hasConfirmedBoosters || hasCards || hasScores || hasModifiedTime
    
    initialized.value = hasBeenModified
    console.log('� Match initialization status:', { initialized: initialized.value, hasBeenModified })
    
    // Initialize match phase system
    initializeMatchPhase()
  } catch (error) {
    console.error('Error loading match:', error)
    router.push('/admin')
  }
}

// Match phase management functions
function initializeMatchPhase() {
  if (!match.value || !matchSettings.value) return
  
  // Calculate total match time based on match settings
  const settings = matchSettings.value
  const quarterTimeSeconds = settings.quarter_duration_minutes * 60
  const breakTimeSeconds = settings.break_duration_minutes * 60
  const halftimeTimeSeconds = settings.halftime_duration_minutes * 60
  
  // Calculate total match time based on quarters and breaks
  const totalQuarterTime = settings.quarters_count * quarterTimeSeconds
  
  let totalBreakTime = 0
  if (settings.quarters_count === 1) {
    // Single quarter game - no breaks at all
    totalBreakTime = 0
  } else if (settings.quarters_count === 2) {
    // For 2-quarter games (halves), there's halftime between them
    totalBreakTime = halftimeTimeSeconds
  } else if (settings.quarters_count > 2) {
    // For multi-quarter games: regular breaks + halftime at middle
    const numberOfBreaks = settings.quarters_count - 1
    const regularBreaks = numberOfBreaks - 1 // All breaks except halftime
    totalBreakTime = regularBreaks * breakTimeSeconds + halftimeTimeSeconds
  }
  
  totalMatchTime.value = totalQuarterTime + totalBreakTime
  
  // Determine current phase based on time_left
  calculateCurrentPhase()
}

function calculateCurrentPhase() {
  if (!match.value || !matchSettings.value) return
  
  const timeElapsed = totalMatchTime.value - match.value.time_left
  const settings = matchSettings.value
  const quarterTimeSeconds = settings.quarter_duration_minutes * 60
  const breakTimeSeconds = settings.break_duration_minutes * 60
  const halftimeTimeSeconds = settings.halftime_duration_minutes * 60
  
  let currentTime = 0
  
  // Iterate through the match phases to determine current phase
  for (let quarter = 1; quarter <= settings.quarters_count; quarter++) {
    // Quarter time
    if (timeElapsed <= currentTime + quarterTimeSeconds) {
      currentPhase.value = 'quarter'
      currentPeriod.value = quarter
      phaseTimeLeft.value = quarterTimeSeconds - (timeElapsed - currentTime)
      return
    }
    currentTime += quarterTimeSeconds
    
    // Break or halftime after quarter (except after last quarter)
    if (quarter < settings.quarters_count) {
      // For 2-quarter games, the break is always halftime
      // For multi-quarter games, halftime is at the middle quarter
      const isHalftime = settings.quarters_count === 2 || 
                        (quarter === Math.floor(settings.quarters_count / 2) && settings.quarters_count > 2)
      const breakDuration = isHalftime ? halftimeTimeSeconds : breakTimeSeconds
      
      if (timeElapsed <= currentTime + breakDuration) {
        currentPhase.value = isHalftime ? 'halftime' : 'break'
        currentPeriod.value = quarter
        phaseTimeLeft.value = breakDuration - (timeElapsed - currentTime)
        return
      }
      currentTime += breakDuration
    }
  }
  
  // Match is finished
  currentPhase.value = 'finished'
  currentPeriod.value = settings.quarters_count
  phaseTimeLeft.value = 0
}

function getCalculatedMatchTime(): number {
  if (!matchSettings.value) return 1800 // Default 30 minutes
  
  const settings = matchSettings.value
  const quarterTimeSeconds = settings.quarter_duration_minutes * 60
  const breakTimeSeconds = settings.break_duration_minutes * 60
  const halftimeTimeSeconds = settings.halftime_duration_minutes * 60
  
  // Calculate total match time based on quarters and breaks
  const totalQuarterTime = settings.quarters_count * quarterTimeSeconds
  
  let totalBreakTime = 0
  if (settings.quarters_count === 1) {
    // Single quarter game - no breaks at all
    totalBreakTime = 0
  } else if (settings.quarters_count === 2) {
    // For 2-quarter games (halves), there's halftime between them
    totalBreakTime = halftimeTimeSeconds
  } else if (settings.quarters_count > 2) {
    // For multi-quarter games: regular breaks + halftime at middle
    const numberOfBreaks = settings.quarters_count - 1
    const regularBreaks = numberOfBreaks - 1 // All breaks except halftime
    totalBreakTime = regularBreaks * breakTimeSeconds + halftimeTimeSeconds
  }
  
  return totalQuarterTime + totalBreakTime
}

function handlePhaseTransition() {
  if (!matchSettings.value) return
  
  // Check if current phase time has expired
  if (phaseTimeLeft.value <= 0) {
    // Move to next phase
    const settings = matchSettings.value
    
    if (currentPhase.value === 'quarter') {
      if (currentPeriod.value < settings.quarters_count) {
        // Move to break or halftime
        // For 2-quarter games, the break is always halftime
        // For multi-quarter games, halftime is at the middle quarter
        const isHalftime = settings.quarters_count === 2 || 
                          (currentPeriod.value === Math.floor(settings.quarters_count / 2) && settings.quarters_count > 2)
        currentPhase.value = isHalftime ? 'halftime' : 'break'
        phaseTimeLeft.value = isHalftime 
          ? settings.halftime_duration_minutes * 60 
          : settings.break_duration_minutes * 60
      } else {
        // Match finished
        currentPhase.value = 'finished'
        phaseTimeLeft.value = 0
        finishMatch()
      }
    } else if (currentPhase.value === 'break' || currentPhase.value === 'halftime') {
      // Move to next quarter
      currentPeriod.value++
      currentPhase.value = 'quarter'
      phaseTimeLeft.value = settings.quarter_duration_minutes * 60
    }
    
    console.log('� Phase transition:', { 
      phase: currentPhase.value, 
      period: currentPeriod.value, 
      timeLeft: phaseTimeLeft.value 
    })
  }
}

async function loadTeams() {
  try {
    const { data, error } = await supabase
      .from('teams')
      .select('*')

    if (error) {
      console.error('Error loading teams:', error)
      throw error // Re-throw to be caught in onMounted
    }

    const teamsMap: Record<string, any> = {}
    data?.forEach(team => {
      teamsMap[team.id] = team
    })
    teams.value = teamsMap
  } catch (error) {
    console.error('❌ Critical error loading teams:', error)
    throw error // Re-throw to trigger outer error handling
  }
}



// Process update queue sequentially to prevent race conditions
async function processUpdateQueue() {
  if (isProcessingQueue || updateQueue.length === 0) return
  
  isProcessingQueue = true
  console.log('📝 Processing update queue with', updateQueue.length, 'items')
  
  while (updateQueue.length > 0) {
    const updateFn = updateQueue.shift()
    if (updateFn) {
      try {
        console.log('📝 Processing queued update...')
        await updateFn()
        console.log('✅ Queued update completed successfully')
      } catch (error) {
        console.error('❌ Error processing queued update:', error)
      }
    }
  }
  
  isProcessingQueue = false
  console.log('📝 Update queue processing completed')
}

// Queue an update to prevent race conditions
function queueUpdate(updateFn: () => Promise<any>) {
  updateQueue.push(updateFn)
  processUpdateQueue()
}

async function updateMatch(updates: Partial<any>) {
  console.log('🔧 updateMatch function started')
  
  return new Promise((resolve, reject) => {
    // Add timeout protection - reject after 10 seconds
    const timeoutId = setTimeout(() => {
      console.error('❌ updateMatch timeout - operation took too long')
      reject(new Error('Update operation timed out after 10 seconds'))
    }, 10000)
    
    const updateFn = async () => {
      try {
        console.log('📝 Processing queued update with:', updates)
        console.log('📝 Match ID:', props.id)
        console.log('📝 Current match state before update:', {
          status: match.value?.status,
          score_a: match.value?.score_a,
          score_b: match.value?.score_b,
          boosters: match.value?.boosters ? 'present' : 'absent'
        })
        
        // Try the simplest possible update
        const result = await supabase
          .from('matches')
          .update(updates)
          .eq('id', props.id)
        
        console.log('📝 Supabase update result:', result)
        
        if (result.error) {
          console.error('❌ Error updating match:', result.error)
          clearTimeout(timeoutId)
          reject(result.error)
          return
        }

        console.log('✅ Match updated successfully in database')
        
        // Update local state
        if (match.value) {
          Object.assign(match.value, updates)
          console.log('✅ Local state updated:', { 
            status: match.value.status,
            updateType: Object.keys(updates).join(', ')
          })
        }
        
        // Add a small delay to ensure database changes propagate
        await new Promise(resolve => setTimeout(resolve, 100))
        
        clearTimeout(timeoutId)
        resolve({ success: true })
      } catch (error) {
        console.error('❌ Exception updating match:', error)
        clearTimeout(timeoutId)
        reject(error)
      }
    }
    
    queueUpdate(updateFn)
  })
}

function startTimer() {
  if (timer.value) clearInterval(timer.value)
  
  timer.value = setInterval(async () => {
    if (match.value && match.value.status === 'active' && match.value.time_left > 0) {
      const newTimeLeft = match.value.time_left - 1
      match.value.time_left = newTimeLeft
      
      // Update phase time left
      if (phaseTimeLeft.value > 0) {
        phaseTimeLeft.value--
      }
      
      // Handle phase transitions
      handlePhaseTransition()
      
      // Update database every 5 seconds or when time reaches 0
      if (newTimeLeft % 5 === 0 || newTimeLeft === 0) {
        await updateMatch({ time_left: newTimeLeft })
        
        if (newTimeLeft === 0) {
          await finishMatch()
        }
      }
    }
  }, 1000)
}

function startPenaltyTimer() {
  if (penaltyTimer.value) clearInterval(penaltyTimer.value)
  
  penaltyTimer.value = setInterval(async () => {
    if (!match.value?.cards?.player_penalties) return
    
    const now = new Date()
    let hasExpiredPenalties = false
    const cards = { ...match.value.cards }
    const updatedPenalties = { ...cards.player_penalties }
    
    // Check all active penalties
    Object.keys(updatedPenalties).forEach(teamKey => {
      Object.keys(updatedPenalties[teamKey] || {}).forEach(playerId => {
        const penalty = updatedPenalties[teamKey][playerId]
        if (penalty && penalty.expires_at !== 'never') {
          const expiresAt = new Date(penalty.expires_at)
          if (now >= expiresAt) {
            delete updatedPenalties[teamKey][playerId]
            hasExpiredPenalties = true
          }
        }
      })
    })
    
    // Update database if any penalties expired
    if (hasExpiredPenalties) {
      cards.player_penalties = updatedPenalties
      await updateMatch({ cards })
    }
  }, 1000)
}

function stopTimer() {
  if (timer.value) {
    clearInterval(timer.value)
    timer.value = null
  }
}

function stopPenaltyTimer() {
  if (penaltyTimer.value) {
    clearInterval(penaltyTimer.value)
    penaltyTimer.value = null
  }
}

async function playMatch() {
  if (buttonStates.value.play) return // Prevent double-clicks
  
  setButtonState('play', true)
  try {
    console.log('▶️ Starting match...')
    await updateMatch({ status: 'active' })
    
    // Record timeline event
    const event = createTimelineEvent<MatchStatusEvent>(
      match.value?.score_a === 0 && match.value?.score_b === 0 ? 'match_started' : 'match_resumed',
      null,
      { status: 'active' },
      match.value?.time_left || 0
    )
    await recordTimelineEvent(event)
    
    startTimer()
    startPenaltyTimer()
    console.log('✅ Match started successfully')
  } catch (error) {
    console.error('❌ Failed to start match:', error)
    alert('Failed to start match. Please try again.')
  } finally {
    setButtonState('play', false)
  }
}

async function pauseMatch() {
  if (buttonStates.value.pause) return // Prevent double-clicks
  
  setButtonState('pause', true)
  try {
    console.log('⏸️ Pausing match...')
    await updateMatch({ status: 'paused' })
    
    // Record timeline event
    const event = createTimelineEvent<MatchStatusEvent>(
      'match_paused',
      null,
      { status: 'paused' },
      match.value?.time_left || 0
    )
    await recordTimelineEvent(event)
    
    stopTimer()
    stopPenaltyTimer()
    console.log('✅ Match paused successfully')
  } catch (error) {
    console.error('❌ Failed to pause match:', error)
    alert('Failed to pause match. Please try again.')
  } finally {
    setButtonState('pause', false)
  }
}

async function finishMatch() {
  if (buttonStates.value.finish) return // Prevent double-clicks
  
  setButtonState('finish', true)
  try {
    console.log('🏁 Finishing match...')
    await updateMatch({ status: 'finished' })
    
    // Record timeline event
    const event = createTimelineEvent<MatchStatusEvent>(
      'match_finished',
      null,
      { status: 'finished' },
      match.value?.time_left || 0
    )
    await recordTimelineEvent(event)
    
    stopTimer()
    stopPenaltyTimer()
    console.log('✅ Match finished successfully')
  } catch (error) {
    console.error('❌ Failed to finish match:', error)
    alert('Failed to finish match. Please try again.')
  } finally {
    setButtonState('finish', false)
  }
}

async function updateScore(team: 'a' | 'b', increment: number) {
  const teamKey = `score_${team}`
  
  console.log(`🔢 updateScore called: team=${team}, increment=${increment}`)
  
  // Clear existing timeout for this team
  if (scoreUpdateTimeouts.value[teamKey]) {
    clearTimeout(scoreUpdateTimeouts.value[teamKey])
  }
  
  // Calculate new score
  const currentScore = team === 'a' ? (match.value?.score_a || 0) : (match.value?.score_b || 0)
  const newScore = Math.max(0, currentScore + increment)
  
  console.log(`🔢 Score change: ${currentScore} -> ${newScore} for team ${team.toUpperCase()}`)
  
  // Update local display immediately for responsive UI
  if (match.value) {
    if (team === 'a') {
      match.value.score_a = newScore
    } else {
      match.value.score_b = newScore
    }
    console.log(`🔢 Local UI updated immediately: ${team}=${newScore}`)
  }
  
  // Debounce the database update
  scoreUpdateTimeouts.value[teamKey] = setTimeout(async () => {
    try {
      const updates = team === 'a' 
        ? { score_a: newScore }
        : { score_b: newScore }
      
      console.log(`🔢 Sending score update to database:`, updates)
      await updateMatch(updates)
      
      // Record goal event in timeline (only on increment, not decrement)
      if (increment > 0) {
        const goalEvent = createTimelineEvent<GoalEvent>(
          'goal',
          team,
          {
            score_a: team === 'a' ? newScore : (match.value?.score_a || 0),
            score_b: team === 'b' ? newScore : (match.value?.score_b || 0),
            pc: false // We'll track PC goals separately
          },
          match.value?.time_left || 0
        )
        await recordTimelineEvent(goalEvent)
      }
      
      console.log(`✅ Score updated for team ${team.toUpperCase()}:`, updates)
    } catch (error) {
      console.error(`❌ Failed to update score for team ${team}:`, error)
      // Revert local changes on error
      if (match.value) {
        if (team === 'a') {
          match.value.score_a = currentScore
        } else {
          match.value.score_b = currentScore
        }
      }
    }
    delete scoreUpdateTimeouts.value[teamKey]
  }, 300) // 300ms debounce
}

async function updatePC(team: 'a' | 'b', increment: number) {
  const teamKey = `pc_${team}`
  
  console.log(`🏒 updatePC called: team=${team}, increment=${increment}`)
  
  // Clear existing timeout for this team
  if (pcUpdateTimeouts.value[teamKey]) {
    clearTimeout(pcUpdateTimeouts.value[teamKey])
  }
  
  // Calculate new PC count
  const currentPC = team === 'a' ? (match.value?.pc_a || 0) : (match.value?.pc_b || 0)
  const newPC = Math.max(0, currentPC + increment)
  
  console.log(`🏒 PC change: ${currentPC} -> ${newPC} for team ${team.toUpperCase()}`)
  
  // Update local display immediately for responsive UI
  if (match.value) {
    if (team === 'a') {
      match.value.pc_a = newPC
    } else {
      match.value.pc_b = newPC
    }
    console.log(`🏒 Local UI updated immediately: PC ${team}=${newPC}`)
  }
  
  // Debounce the database update
  pcUpdateTimeouts.value[teamKey] = setTimeout(async () => {
    try {
      const updates = team === 'a' 
        ? { pc_a: newPC }
        : { pc_b: newPC }
      
      console.log(`🏒 Sending PC update to database:`, updates)
      await updateMatch(updates)
      
      // Record penalty corner event in timeline (only on increment, not decrement)
      if (increment > 0) {
        const pcEvent = createTimelineEvent<PenaltyCornerEvent>(
          'penalty_corner',
          team,
          {
            pc_a: team === 'a' ? newPC : (match.value?.pc_a || 0),
            pc_b: team === 'b' ? newPC : (match.value?.pc_b || 0)
          },
          match.value?.time_left || 0
        )
        await recordTimelineEvent(pcEvent)
      }
      
      console.log(`✅ PC updated for team ${team.toUpperCase()}:`, updates)
    } catch (error) {
      console.error(`❌ Failed to update PC for team ${team}:`, error)
      // Revert local changes on error
      if (match.value) {
        if (team === 'a') {
          match.value.pc_a = currentPC
        } else {
          match.value.pc_b = currentPC
        }
      }
    }
    delete pcUpdateTimeouts.value[teamKey]
  }, 300) // 300ms debounce
}

async function addCardToPlayer(team: 'a' | 'b', player: Player, cardType: 'yellow' | 'green' | 'red') {
  const now = new Date().toISOString()
  const playerId = `${player.number}_${player.name.replace(/\s+/g, '_')}`
  
  // Calculate penalty duration
  let penaltyDuration = 0
  switch (cardType) {
    case 'yellow':
      penaltyDuration = 5 * 60 * 1000 // 5 minutes in milliseconds
      break
    case 'green':
      penaltyDuration = 2 * 60 * 1000 // 2 minutes in milliseconds
      break
    case 'red':
      penaltyDuration = 0 // Out for the entire game, no expiration
      break
  }
  
  // Store penalties in existing cards JSONB column with extended structure
  const cards = { ...(match.value?.cards || {}) }
  const teamKey = `team_${team}`
  
  // Initialize team data if it doesn't exist
  if (!cards[teamKey]) {
    cards[teamKey] = { yellow: 0, green: 0, red: 0 }
  }
  
  // Update team-level card count
  cards[teamKey][cardType] = (cards[teamKey][cardType] || 0) + 1
  
  // Store player penalties in the cards structure (extended format)
  if (!cards.player_penalties) {
    cards.player_penalties = {}
  }
  if (!cards.player_penalties[teamKey]) {
    cards.player_penalties[teamKey] = {}
  }
  
  const penalty: PlayerPenalty = {
    type: cardType,
    expires_at: cardType === 'red' ? 'never' : new Date(Date.now() + penaltyDuration).toISOString()
  }
  
  cards.player_penalties[teamKey][playerId] = penalty
  
  // Store player info for display
  if (!cards.player_info) {
    cards.player_info = {}
  }
  if (!cards.player_info[teamKey]) {
    cards.player_info[teamKey] = {}
  }
  cards.player_info[teamKey][playerId] = {
    name: player.name,
    number: player.number,
    position: player.position
  }
  
  await updateMatch({ cards })
  
  // Record card event in timeline
  const cardEvent = createTimelineEvent<CardIssuedEvent>(
    'card_issued',
    team,
    {
      card_type: cardType,
      player_name: player.name,
      player_number: player.number,
      duration: cardType === 'red' ? 'never' : (penaltyDuration / 1000)
    },
    match.value?.time_left || 0
  )
  await recordTimelineEvent(cardEvent)
}

// Booster selection functions
async function startBoosterSelection() {
  if (buttonStates.value.spinners) return // Prevent double-clicks
  
  setButtonState('spinners', true)
  try {
    console.log('🎰 Starting booster selection...', { match: match.value?.status })
    if (match.value?.status !== 'active' && match.value?.status !== 'pending') {
      console.log('⚠️ Cannot start booster selection - invalid match status')
      return
    }
    
    showBoosterSelection.value = true
    selectedBoosters.value = { teamA: [], teamB: [] }
    boosterPhase.value = 'ready'
    currentTeamSpinning.value = null
    
    console.log('🎰 Updating database with booster selection state...')
    // Update match to show booster selection is active on scoreboard
    // Using boosters column to store selection state since we don't have dedicated columns yet
    const currentBoosters = match.value?.boosters || {}
    await updateMatch({ 
      boosters: {
        ...currentBoosters,
        selection_active: true,
        selection_phase: 'ready',
        is_spinning: false,
        current_team: null,
        spinning_slot: 0,
        current_boosters: {
          teamA: [],
          teamB: []
        }
      }
    })
    console.log('✅ Booster selection state updated in database')
  } catch (error) {
    console.error('❌ Failed to start booster selection:', error)
    alert('Failed to start booster selection. Please try again.')
    showBoosterSelection.value = false
  } finally {
    setButtonState('spinners', false)
  }
}

async function spinCurrentPhase() {
  console.log('🎰 spinCurrentPhase called:', { 
    isSpinning: isSpinning.value, 
    availableBoosters: availableBoosters.value.length,
    currentPhase: boosterPhase.value 
  })
  
  // Stronger guards
  if (isSpinning.value) {
    console.log('⚠️ Already spinning, ignoring call')
    return
  }
  
  if (availableBoosters.value.length === 0) {
    console.log('⚠️ No available boosters, cannot spin')
    return
  }
  
  if (boosterPhase.value === 'complete') {
    console.log('⚠️ Selection already complete, cannot spin')
    return
  }
  
  // Set spinning immediately to prevent race conditions
  isSpinning.value = true
  spinningSlot.value = 0
  
  // Backup timeout to ensure spinning never gets stuck longer than 5 seconds
  const backupTimeout = setTimeout(() => {
    console.warn('⚠️ Backup timeout triggered - force resetting spin state after 5 seconds')
    isSpinning.value = false
    currentTeamSpinning.value = null
  }, 5000) // Increased to 5 seconds to allow for database updates
  
  // Play spinning sound effect
  try {
    await playSpinningSound()
  } catch (error) {
    console.warn('🔊 Failed to play spinning sound:', error)
  }
  
  // Determine current phase
  let targetTeam: 'A' | 'B'
  let boosterIndex: number
  
  const currentPhase = boosterPhase.value as BoosterPhase
  switch (currentPhase) {
    case 'ready':
      boosterPhase.value = 'team-a-first'
      targetTeam = 'A'
      boosterIndex = 0
      break
    case 'team-a-first':
      boosterPhase.value = 'team-a-second'
      targetTeam = 'A'
      boosterIndex = 1
      break
    case 'team-a-second':
      boosterPhase.value = 'team-b-first'
      targetTeam = 'B'
      boosterIndex = 0
      break
    case 'team-b-first':
      boosterPhase.value = 'team-b-second'
      targetTeam = 'B'
      boosterIndex = 1
      break
    case 'team-b-second':
      // This should not happen - team-b-second should be completed in the timeout
      console.warn('⚠️ team-b-second phase called again - selection should be complete')
      boosterPhase.value = 'complete'
      isSpinning.value = false
      clearTimeout(backupTimeout)
      return
    case 'complete':
      console.warn('⚠️ Spin called but selection is already complete')
      isSpinning.value = false
      clearTimeout(backupTimeout)
      return
    default:
      console.error('❌ Unknown booster phase:', boosterPhase.value)
      isSpinning.value = false
      clearTimeout(backupTimeout)
      return
  }
  
  console.log('🎯 Phase transition:', { 
    newPhase: boosterPhase.value, 
    targetTeam, 
    boosterIndex 
  })
  
  currentTeamSpinning.value = targetTeam
  
  // Update database to show spinning state on scoreboard
  const currentBoosters = match.value?.boosters || {}
  try {
    await updateMatch({
      boosters: {
        ...currentBoosters,
        selection_active: true,
        selection_phase: boosterPhase.value,
        is_spinning: true,
        current_team: targetTeam,
        spinning_slot: 0
      }
    })
    console.log('✅ Database updated with spinning state')
  } catch (error) {
    console.error('❌ Failed to update database with spinning state:', error)
    // Reset spinning state on database error
    isSpinning.value = false
    clearTimeout(backupTimeout)
    return
  }
  
  // Animate slot spinning with periodic DB updates for scoreboard sync
  const spinInterval = setInterval(async () => {
    const newSlot = Math.floor(Math.random() * availableBoosters.value.length)
    spinningSlot.value = newSlot
    
    // Update database every few spins to keep scoreboard in sync
    // Use modulo to reduce database calls while still providing visual updates
    if (newSlot % 3 === 0) {
      try {
        await updateMatch({
          boosters: {
            ...currentBoosters,
            selection_active: true,
            selection_phase: boosterPhase.value,
            is_spinning: true,
            current_team: targetTeam,
            spinning_slot: newSlot
          }
        })
      } catch (error) {
        // Silently fail on update errors during spinning to avoid interrupting animation
        console.log('⚠️ Spin update failed (continuing):', error)
      }
    }
  }, 100)
  
  // Stop spinning after 2 seconds and assign booster
  setTimeout(async () => {
    try {
      console.log('🎰 Timeout triggered - stopping spin...')
      clearInterval(spinInterval)
      clearTimeout(backupTimeout) // Clear the backup timeout since we're handling completion properly
      
      // Get available boosters (excluding already selected ones)
      const excludeIds = [...selectedBoosters.value.teamA, ...selectedBoosters.value.teamB].map(b => b.id)
      const availableForSelection = availableBoosters.value.filter(b => !excludeIds.includes(b.id))
      
      console.log('🎰 Available boosters for selection:', {
        total: availableBoosters.value.length,
        available: availableForSelection.length,
        excluded: excludeIds.length,
        targetTeam
      })
      
      if (availableForSelection.length > 0) {
        const randomIndex = Math.floor(Math.random() * availableForSelection.length)
        const selectedBooster = availableForSelection[randomIndex]
        
        if (selectedBooster) {
          spinningSlot.value = availableBoosters.value.findIndex(b => b.id === selectedBooster.id)
          
          // Add to appropriate team
          if (targetTeam === 'A') {
            selectedBoosters.value.teamA.push(selectedBooster)
          } else {
            selectedBoosters.value.teamB.push(selectedBooster)
          }
          
          console.log('🎯 Booster selected:', {
            booster: selectedBooster.name,
            team: targetTeam,
            teamA_count: selectedBoosters.value.teamA.length,
            teamB_count: selectedBoosters.value.teamB.length
          })
          
          // Play selection sound effect
          try {
            await playBoosterSelectionSound()
          } catch (error) {
            console.warn('🔊 Failed to play selection sound:', error)
          }
        }
      } else {
        console.warn('⚠️ No available boosters for selection!')
      }
    
    // Check if we're done
    if (boosterPhase.value === 'team-b-second') {
      console.log('🎯 All teams finished spinning, setting phase to complete')
      boosterPhase.value = 'complete'
      
      // Don't auto-confirm in manual mode - let user confirm manually
      // Only auto-confirm if this was triggered programmatically
      console.log('🎯 Selection complete - user can now confirm boosters manually')
    }
    
    // Update scoreboard with final result - spinning stopped
    const currentBoosters = match.value?.boosters || {}
    try {
      await updateMatch({
        boosters: {
          ...currentBoosters,
          selection_active: true,
          selection_phase: boosterPhase.value,
          is_spinning: false,
          current_team: targetTeam,
          spinning_slot: spinningSlot.value,
          current_boosters: {
            teamA: selectedBoosters.value.teamA,
            teamB: selectedBoosters.value.teamB
          }
        }
      })
    } catch (updateError) {
      console.error('❌ Failed to update match after spin:', updateError)
    }
    
    console.log('🎰 Updated database after spin completion:', {
      phase: boosterPhase.value,
      teamA: selectedBoosters.value.teamA,
      teamB: selectedBoosters.value.teamB,
      teamA_length: selectedBoosters.value.teamA.length,
      teamB_length: selectedBoosters.value.teamB.length
    })
    
    isSpinning.value = false
    currentTeamSpinning.value = null
    
    console.log('🎯 Spin completed successfully. Phase:', boosterPhase.value)
    
    } catch (error) {
      console.error('❌ Error in spin timeout:', error)
      // Always reset spinning state on error
      isSpinning.value = false
      currentTeamSpinning.value = null
    } finally {
      // Always clear the backup timeout
      clearTimeout(backupTimeout)
    }
  }, 2000)
}

async function confirmBoosters() {
  console.log('🎯 confirmBoosters() called - starting confirmation process')
  
  if (!match.value) {
    console.error('❌ No match found, cannot confirm boosters')
    return
  }
  
  // Get booster data from database (not local state)
  const currentBoosters = match.value.boosters?.current_boosters || { teamA: [], teamB: [] }
  
  console.log('🎯 Confirming boosters from database...', {
    raw_boosters: match.value.boosters,
    currentBoosters,
    teamA: currentBoosters.teamA,
    teamB: currentBoosters.teamB,
    teamA_length: currentBoosters.teamA?.length || 0,
    teamB_length: currentBoosters.teamB?.length || 0,
    path_check: {
      has_boosters: !!match.value.boosters,
      has_current_boosters: !!match.value.boosters?.current_boosters,
      current_boosters_keys: match.value.boosters?.current_boosters ? Object.keys(match.value.boosters.current_boosters) : []
    }
  })
  
  // Check if we actually have boosters to confirm
  if (!currentBoosters.teamA?.length || !currentBoosters.teamB?.length) {
    console.error('❌ Cannot confirm boosters - missing selections:', {
      teamA_count: currentBoosters.teamA?.length || 0,
      teamB_count: currentBoosters.teamB?.length || 0
    })
    alert('Please complete booster selection for both teams before confirming!')
    return
  }
  
  // Store boosters in scoreboard-compatible format
  const boostersForScoreboard = {
    teamA: currentBoosters.teamA,
    teamB: currentBoosters.teamB
  }
  
  const finalBoosterData = {
    // Available boosters for each team (not yet activated)
    teamA: currentBoosters.teamA.map((booster: any) => ({
      ...booster,
      available: true,
      activated: false,
      used: false
    })),
    teamB: currentBoosters.teamB.map((booster: any) => ({
      ...booster,
      available: true,
      activated: false,
      used: false
    })),
    // Clear selection state completely
    selection_active: false,
    selection_phase: null,
    is_spinning: false,
    current_team: null,
    spinning_slot: null,
    current_boosters: null
  }
  
  console.log('🎯 Updating database with final booster data:', {
    finalBoosterData,
    teamA: finalBoosterData.teamA,
    teamB: finalBoosterData.teamB,
    teamA_length: finalBoosterData.teamA?.length,
    teamB_length: finalBoosterData.teamB?.length
  })
  
  await updateMatch({ 
    boosters: finalBoosterData
  })
  
  console.log('✅ Database updated! Boosters should now be visible on scoreboard')
  
  console.log('🎯 Boosters confirmed and modal closing')
  showBoosterSelection.value = false
  selectedBoosters.value = { teamA: [], teamB: [] }
  autoConfirmationPending.value = false
}

function cancelBoosterSelection() {
  console.log('🚫 Canceling booster selection')
  showBoosterSelection.value = false
  selectedBoosters.value = { teamA: [], teamB: [] }
  isSpinning.value = false
  boosterPhase.value = 'ready'
  autoConfirmationPending.value = false
  currentTeamSpinning.value = null
  
  // Clear booster selection state in database so scoreboard hides overlay
  if (match.value?.boosters) {
    const currentBoosters = { ...match.value.boosters }
    delete currentBoosters.selection_active
    delete currentBoosters.selection_phase
    delete currentBoosters.is_spinning
    delete currentBoosters.current_team
    delete currentBoosters.spinning_slot
    delete currentBoosters.current_boosters
    
    updateMatch({ boosters: currentBoosters }).catch(console.error)
  }
}

// Debug function to log current state
function logBoosterState() {
  console.log('🔍 Current Booster State:', {
    isSpinning: isSpinning.value,
    boosterPhase: boosterPhase.value,
    currentTeamSpinning: currentTeamSpinning.value,
    selectedBoosters: selectedBoosters.value,
    availableBoosters: availableBoosters.value.length,
    matchBoosters: match.value?.boosters,
    showBoosterSelection: showBoosterSelection.value
  })
}

// Debug function to manually complete selection
function forceCompleteSelection() {
  console.log('🔧 Forcing selection completion...')
  
  // Mock selection of 2 boosters for each team
  if (availableBoosters.value.length >= 4) {
    selectedBoosters.value = {
      teamA: availableBoosters.value.slice(0, 2),
      teamB: availableBoosters.value.slice(2, 4)
    }
    boosterPhase.value = 'complete'
    isSpinning.value = false
    currentTeamSpinning.value = null
    
    console.log('🔧 Selection forced to complete with mock boosters')
  } else {
    console.error('❌ Not enough available boosters for mock selection')
  }
}

async function useBooster(team: 'a' | 'b', boosterIndex: number) {
  if (!match.value?.boosters) return
  
  const teamKey = team === 'a' ? 'teamA' : 'teamB'
  const boosters = { ...match.value.boosters }
  
  if (boosters[teamKey] && boosters[teamKey][boosterIndex]) {
    boosters[teamKey][boosterIndex].used = true
    boosters[teamKey][boosterIndex].usedAt = new Date().toISOString()
    
    await updateMatch({ boosters })
  }
}

async function activateTeamBooster(team: 'a' | 'b', boosterIndex: number) {
  if (!match.value?.boosters) return
  
  const boosters = { ...match.value.boosters }
  const teamKey = team === 'a' ? 'teamA' : 'teamB'
  
  if (boosters[teamKey] && boosters[teamKey][boosterIndex] && !boosters[teamKey][boosterIndex].activated && !boosters[teamKey][boosterIndex].countdown) {
    // Create a new array with the updated booster - start with countdown
    const updatedTeamBoosters = [...boosters[teamKey]]
    const booster = updatedTeamBoosters[boosterIndex]
    
    updatedTeamBoosters[boosterIndex] = {
      ...booster,
      countdown: true,
      countdownStartedAt: new Date().toISOString()
    }
    
    // Update the boosters object
    boosters[teamKey] = updatedTeamBoosters
    
    console.log(`🕐 Starting countdown for team ${team.toUpperCase()} booster:`, {
      boosterIndex,
      booster: updatedTeamBoosters[boosterIndex],
      boosterType: booster.id,
      hasDuration: !!booster.duration,
      allBoosters: boosters
    })
    
    // Update database with countdown state
    await updateMatch({ boosters })
    
    // Start 7-second countdown before actual activation
    setTimeout(async () => {
      try {
        // Double-check booster still exists and countdown is still active
        const currentMatch = await supabase
          .from('matches')
          .select('boosters')
          .eq('id', match.value?.id)
          .single()
        
        if (currentMatch.error) {
          console.error('Error checking match state during countdown:', currentMatch.error)
          return
        }
        
        const currentBoosters = currentMatch.data.boosters
        const currentBooster = currentBoosters?.[teamKey]?.[boosterIndex]
        
        if (!currentBooster?.countdown) {
          console.log('🚫 Booster countdown was cancelled or already processed')
          return
        }
        
        // Now actually activate the booster
        console.log(`🚀 Countdown complete - activating booster for team ${team.toUpperCase()}`)
        
        const finalBoosters = { ...currentBoosters }
        const finalUpdatedTeamBoosters = [...finalBoosters[teamKey]]
        
        finalUpdatedTeamBoosters[boosterIndex] = {
          ...currentBooster,
          activated: true,
          activatedAt: new Date().toISOString(),
          countdown: false // Clear countdown flag
        }
        
        finalBoosters[teamKey] = finalUpdatedTeamBoosters
        
        // Play booster sound effect
        await playBoosterSound(booster)
        
        // Special handling for different booster types
        const updates: any = { boosters: finalBoosters }
        
        if (booster.id === 'coach_stroke') {
          // Pause the match for coach stroke execution
          console.log('🎯 Coach stroke activated - pausing match for execution')
          updates.status = 'paused'
          stopTimer()
          stopPenaltyTimer()
        } else if (booster.id === 'goalie_timeout') {
          // For goalie timeout, we might want to add special match state
          console.log('🥅 Goalie timeout activated - opposing goalie benched')
          updates.special_state = `goalie_timeout_${team === 'a' ? 'b' : 'a'}`
        }
        
        await updateMatch(updates)
        
        // Record booster activation in timeline
        const boosterEvent = createTimelineEvent<BoosterActivatedEvent>(
          'booster_activated',
          team,
          {
            booster_id: booster.id || '',
            booster_name: booster.name || booster.title || 'Unknown Booster',
            booster_icon: booster.icon || '⚡',
            duration: booster.duration
          },
          match.value?.time_left || 0
        )
        await recordTimelineEvent(boosterEvent)
        
        // For timed boosters, set up countdown timer with 1-second warning and auto-deactivation
        if (booster.duration && booster.duration > 0) {
          console.log(`⏰ Timed booster activated: ${booster.name} for ${booster.duration} minute(s)`)
          startBoosterTimer(booster, team, boosterIndex)
        } else {
          console.log(`⚡ Instant effect booster activated: ${booster.name}`)
        }
        
      } catch (error) {
        console.error('Error during booster activation after countdown:', error)
      }
    }, 10000) // 10 seconds countdown
  }
}

async function triggerMaddie(selectedMaddie?: any) {
  console.log('🎪 Trigger Maddie called', { selectedMaddie, currentState: match.value?.maddie })
  
  if (selectedMaddie) {
    // New system: Use selected maddie with 7-second countdown
    const maddieData = {
      ...selectedMaddie,
      countdown: true,
      countdownStartedAt: new Date().toISOString()
    }
    
    console.log('🕐 Starting maddie countdown:', maddieData)
    await updateMatch({ maddie: maddieData })
    
    // Start 7-second countdown before actual activation
    setTimeout(async () => {
      try {
        // Double-check maddie countdown is still active
        const currentMatch = await supabase
          .from('matches')
          .select('maddie')
          .eq('id', match.value?.id)
          .single()
        
        if (currentMatch.error) {
          console.error('Error checking match state during maddie countdown:', currentMatch.error)
          return
        }
        
        const currentMaddie = currentMatch.data.maddie
        
        if (typeof currentMaddie !== 'object' || !currentMaddie?.countdown) {
          console.log('🚫 Maddie countdown was cancelled or already processed')
          return
        }
        
        // Now actually activate the maddie
        console.log('🚀 Maddie countdown complete - activating maddie!')
        
        const finalMaddieData = {
          ...currentMaddie,
          activated: true,
          activatedAt: new Date().toISOString(),
          countdown: false // Clear countdown flag
        }
        
        // Play maddie sound effect
        await playMaddieSound()
        
        await updateMatch({ maddie: finalMaddieData })
        
        // Record maddie activation in timeline
        const maddieEvent = createTimelineEvent<MaddieActivatedEvent>(
          'maddie_activated',
          null,
          {
            maddie_id: currentMaddie.id || '',
            maddie_name: currentMaddie.name || currentMaddie.title || 'Unknown Maddie',
            maddie_icon: currentMaddie.icon || '🎪',
            duration: currentMaddie.duration ? currentMaddie.duration / 60 : undefined // Convert seconds to minutes
          },
          match.value?.time_left || 0
        )
        await recordTimelineEvent(maddieEvent)
        
        // Start maddie duration timer if the maddie has a duration
        if (currentMaddie.duration && currentMaddie.duration > 0) {
          console.log(`🕐 Starting maddie timer for ${currentMaddie.duration} seconds`)
          
          // Start visual timer in match control
          startMaddieTimer(currentMaddie)
          
          // Start database timer for auto-deactivation
          setTimeout(async () => {
            try {
              // Check if maddie is still active before expiring it
              const currentMatchCheck = await supabase
                .from('matches')
                .select('maddie')
                .eq('id', match.value?.id)
                .single()
              
              if (currentMatchCheck.error) {
                console.error('Error checking match state during maddie timer:', currentMatchCheck.error)
                return
              }
              
              const currentMaddieCheck = currentMatchCheck.data.maddie
              
              if (typeof currentMaddieCheck === 'object' && currentMaddieCheck?.activated) {
                console.log('🚫 Maddie duration expired - deactivating')
                await updateMatch({ maddie: false }) // Reset to inactive
                clearMaddieTimer() // Clear the visual timer
              }
            } catch (error) {
              console.error('Error during maddie timer expiration:', error)
            }
          }, currentMaddie.duration * 1000) // Convert seconds to milliseconds
        }
        
      } catch (error) {
        console.error('Error during maddie activation after countdown:', error)
      }
    }, 10000) // 10 seconds countdown
    
  } else {
    // Legacy system: Toggle boolean maddie state
    const newMaddieState = !match.value?.maddie
    
    // If activating maddie, play sound
    if (newMaddieState) {
      await playMaddieSound()
    }
    
    await updateMatch({ maddie: newMaddieState })
  }
}

async function deactivateMaddie() {
  console.log('🚫 Deactivating maddie manually')
  
  try {
    // Clear any active timer
    clearMaddieTimer()
    
    // Reset maddie state in database
    await updateMatch({ maddie: false })
    
    console.log('✅ Maddie deactivated successfully')
  } catch (error) {
    console.error('Error deactivating maddie:', error)
  }
}

async function toggleBooster(boosterName: string) {
  const boosters = { ...(match.value?.boosters || {}) }
  boosters[boosterName] = !boosters[boosterName]
  
  await updateMatch({ boosters })
}

async function resetTimer() {
  const matchTime = getCalculatedMatchTime()
  await updateMatch({ time_left: matchTime })
  
  // Reinitialize phase tracking
  initializeMatchPhase()
}

async function resumeAfterBooster() {
  console.log('🎯 Resuming match after booster execution')
  // Clear any special match states and resume
  await updateMatch({ 
    status: 'active',
    special_state: null
  })
  startTimer()
  startPenaltyTimer()
}

async function initializeMatch() {
  console.log('🚀 Initialize match clicked', { match: match.value, status: match.value?.status })
  
  if (match.value?.status !== 'pending') {
    console.warn('⚠️ Cannot initialize - match status is not pending:', match.value?.status)
    return
  }
  
  if (initializing.value) {
    console.log('⏳ Already initializing, ignoring click')
    return
  }
  
  try {
    initializing.value = true
    console.log('🔧 Initializing match...')
    
    // First, mark as initialized immediately to provide UI feedback
    console.log('🔄 Setting initialized to true for immediate UI update')
    initialized.value = true
    
    // Force a UI update by triggering Vue reactivity
    await nextTick()
    
    // Then update the database
    console.log('📤 About to call updateMatch...')
    const result = await updateMatch({ 
      status: 'pending',
      score_a: 0,
      score_b: 0,
      pc_a: 0,
      pc_b: 0,
      cards: {},
      boosters: {
        // Explicitly clear all booster selection state
        selection_active: false,
        selection_phase: null,
        is_spinning: false,
        current_team: null,
        spinning_slot: null,
        current_boosters: null,
        teamA: [],
        teamB: []
      },
      time_left: getCalculatedMatchTime()
    })
    console.log('📥 updateMatch completed with result:', result)
    
    // Verify the database update was successful
    if (result && (result as any).success) {
      console.log('✅ Match initialized successfully')
      
      // Force UI update by triggering reactivity
      match.value = { ...match.value }
    } else {
      console.error('❌ Database update failed, reverting initialized state')
      initialized.value = false
      alert('Failed to initialize match. Please check the console and try again.')
    }
  } catch (error) {
    console.error('❌ Error initializing match:', error)
    // Revert the initialized state if there was an error
    initialized.value = false
    alert('Failed to initialize match. Please try again.')
  } finally {
    initializing.value = false
  }
}

async function resetMatch() {
  if (!match.value || resetting.value) return
  
  const confirmed = confirm(
    'Are you sure you want to reset this match?\n\n' +
    'This will:\n' +
    '• Clear all scores (0-0)\n' +
    '• Clear all penalty corners (0-0)\n' +
    '• Remove all player penalties\n' +
    '• Clear all boosters\n' +
    '• Reset timer to 30:00\n' +
    '• Return to initialization state\n\n' +
    'This action cannot be undone!'
  )
  
  if (!confirmed) return
  
  try {
    resetting.value = true
    
    // Reset match to pending state - clears everything
    const matchTime = getCalculatedMatchTime()
    await updateMatch({ 
      status: 'pending',
      score_a: 0,
      score_b: 0,
      pc_a: 0,
      pc_b: 0,
      cards: {},
      boosters: {},
      time_left: matchTime,
      maddie: false
    })
    
    // Stop any running timers
    stopTimer()
    stopPenaltyTimer()
    
    // Reset phase tracking
    currentPhase.value = 'quarter'
    currentPeriod.value = 1
    phaseTimeLeft.value = 0
    totalMatchTime.value = 0
    
    // Reset booster selection state
    showBoosterSelection.value = false
    selectedBoosters.value = { teamA: [], teamB: [] }
    boosterPhase.value = 'ready'
    currentTeamSpinning.value = null
    isSpinning.value = false
    
    // Reset initialization state
    initialized.value = false
    
    console.log('✅ Match reset successfully')
  } catch (error) {
    console.error('❌ Error resetting match:', error)
    alert('Failed to reset match. Please try again.')
  } finally {
    resetting.value = false
  }
}

// Sound helper functions
async function playBoosterSound(booster: any) {
  try {
    if (!booster.sound_file) {
      // Use default booster sound if no specific sound is set
      await SoundManager.playSound('/sounds/booster-activate.mp3', 0.8)
      return
    }

    let soundPath: string
    
    // Check if it's a custom uploaded sound
    if (booster.sound_file.startsWith('custom_')) {
      const customSound = SoundManager.getCustomSound(booster.sound_file)
      if (customSound) {
        soundPath = customSound
      } else {
        console.warn('Custom booster sound not found, using default')
        soundPath = '/sounds/booster-activate.mp3'
      }
    } else {
      // Use predefined sound from the boosters folder
      soundPath = `/sounds/boosters/${booster.sound_file}`
    }
    
    console.log('🔊 Playing booster sound:', soundPath)
    await SoundManager.playSound(soundPath, 0.8)
  } catch (error) {
    console.error('🔊 Error playing booster sound:', error)
    // Fallback to default booster sound from boosters folder
    try {
      await SoundManager.playSound('/sounds/boosters/booster_1.mp3', 0.8)
    } catch (fallbackError) {
      console.error('🔊 Fallback sound also failed:', fallbackError)
    }
  }
}

async function playMaddieSound(maddie?: any) {
  try {
    // If maddie has a custom sound file, try to play it
    if (maddie?.sound_file) {
      if (maddie.sound_file.startsWith('custom_')) {
        // Custom uploaded file - get from localStorage
        const customSoundData = SoundManager.getCustomSound(maddie.sound_file)
        if (customSoundData) {
          await SoundManager.playSound(customSoundData)
          return
        }
      } else {
        // Default file from maddies folder
        await SoundManager.playSound(`/sounds/maddies/${maddie.sound_file}`)
        return
      }
    }

    // Fallback to default maddie sound
    try {
      await SoundManager.playSound('/sounds/maddies/maddie_1.mp3', 0.8)
    } catch (fallbackError) {
      await SoundManager.playSound('/sounds/maddie.mp3', 0.8)
    }
    console.log('🔊 Playing maddie sound')
  } catch (error) {
    console.error('🔊 Error playing maddie sound:', error)
  }
}

async function playSpinningSound() {
  try {
    // Play a spinning/slot machine sound effect
    await SoundManager.playSound('/sounds/booster_spin.wav', 0.6)
    console.log('🔊 Playing spinning sound')
  } catch (error) {
    console.log('🔊 Spinning sound not available, trying fallback')
    try {
      // Fallback to a booster sound for spinning effect
      await SoundManager.playSound('/sounds/boosters/booster_1.mp3', 0.4)
    } catch (fallbackError) {
      console.warn('🔊 No spinning sound available')
    }
  }
}

async function playBoosterSelectionSound() {
  try {
    // Play a selection/ding sound when booster is chosen
    await SoundManager.playSound('/sounds/selection.mp3', 1)
    console.log('🔊 Playing booster selection sound')
  } catch (error) {
    console.log('🔊 Selection sound not available, trying fallback')
    try {
      // Fallback to a different booster sound for selection
      await SoundManager.playSound('/sounds/boosters/booster_2.mp3', 0.5)
    } catch (fallbackError) {
      console.warn('🔊 No selection sound available')
    }
  }
}

async function playTickSound() {
  try {
    // Play a subtle tick sound for each slot change during spinning
    await SoundManager.playSound('/sounds/tick.mp3', 0.3)
  } catch (error) {
    // Silently fail for tick sounds - they're optional
  }
}

// Booster timer management
function startBoosterTimer(booster: any, team: 'a' | 'b', boosterIndex: number) {
  const timerKey = `${team}_${boosterIndex}_${Date.now()}`
  const durationMs = booster.duration * 60 * 1000 // Convert minutes to milliseconds
  const endTime = Date.now() + durationMs

  console.log(`⏰ Starting timer for ${booster.name}: ${booster.duration} minutes`)

  // Set up interval to check for warnings and expiration
  const intervalId = setInterval(() => {
    const now = Date.now()
    const timeLeft = endTime - now

    // Check for 1-second warning
    if (timeLeft <= 1000 && timeLeft > 0 && !activeBoosterTimers.value[timerKey]?.oneSecondWarningPlayed) {
      console.log(`⚠️ 1 second warning for ${booster.name}`)
      playBoosterSound(booster) // Play sound again at 1 second
      if (activeBoosterTimers.value[timerKey]) {
        activeBoosterTimers.value[timerKey].oneSecondWarningPlayed = true
      }
    }

    // Check for expiration
    if (timeLeft <= 0) {
      console.log(`⏰ Booster ${booster.name} expired`)
      clearBoosterTimer(timerKey)
      deactivateBooster(team, boosterIndex)
    }
  }, 100) // Check every 100ms for precision

  // Store timer info
  activeBoosterTimers.value[timerKey] = {
    booster,
    team,
    endTime,
    intervalId,
    oneSecondWarningPlayed: false
  }
}

function clearBoosterTimer(timerKey: string) {
  const timer = activeBoosterTimers.value[timerKey]
  if (timer) {
    clearInterval(timer.intervalId)
    delete activeBoosterTimers.value[timerKey]
  }
}

async function deactivateBooster(team: 'a' | 'b', boosterIndex: number) {
  if (!match.value?.boosters) return
  
  const boosters = { ...match.value.boosters }
  const teamKey = team === 'a' ? 'teamA' : 'teamB'
  
  if (boosters[teamKey] && boosters[teamKey][boosterIndex] && boosters[teamKey][boosterIndex].activated) {
    // Mark booster as expired/finished
    const updatedTeamBoosters = [...boosters[teamKey]]
    updatedTeamBoosters[boosterIndex] = {
      ...updatedTeamBoosters[boosterIndex],
      expired: true,
      expiredAt: new Date().toISOString()
    }
    
    boosters[teamKey] = updatedTeamBoosters
    
    console.log(`🏁 Booster expired for team ${team.toUpperCase()}:`, {
      boosterIndex,
      booster: updatedTeamBoosters[boosterIndex]
    })
    
    await updateMatch({ boosters })
  }
}

async function finishInstantBooster(team: 'a' | 'b', boosterIndex: number) {
  if (!match.value?.boosters) return
  
  const boosters = { ...match.value.boosters }
  const teamKey = team === 'a' ? 'teamA' : 'teamB'
  
  if (boosters[teamKey] && boosters[teamKey][boosterIndex]) {
    const booster = boosters[teamKey][boosterIndex]
    
    // Only allow finishing instant boosters (no duration or 0 duration)
    if (booster.activated && (!booster.duration || booster.duration === 0)) {
      console.log(`🏁 Finishing instant booster ${booster.name} for team ${team.toUpperCase()}`)
      
      const updatedTeamBoosters = [...boosters[teamKey]]
      updatedTeamBoosters[boosterIndex] = {
        ...updatedTeamBoosters[boosterIndex],
        activated: false,
        expired: true,
        expiredAt: new Date().toISOString()
      }
      
      boosters[teamKey] = updatedTeamBoosters
      
      // Clear any special states related to this booster
      let updates: any = { boosters }
      
      if (booster.id === 'goalie_timeout' || booster.id === 'timeout' || booster.id === 'coach_stroke') {
        updates.special_state = null
        console.log(`🏁 Cleared special state for instant booster ${booster.name}`)
      }
      
      await updateMatch(updates)
      console.log(`✅ Instant booster ${booster.name} finished successfully`)
    } else {
      console.warn(`⚠️ Cannot finish booster ${booster.name} - either not activated or has duration`)
    }
  }
}

// Real-time subscription for match updates
let matchSubscription: any = null

// Setup real-time subscription for match updates
function setupRealtimeSubscription() {
  if (!match.value) return

  matchSubscription = supabase
    .channel(`match_${match.value.id}`)
    .on('postgres_changes', {
      event: 'UPDATE',
      schema: 'public',
      table: 'matches',
      filter: `id=eq.${match.value.id}`
    }, (payload) => {
      console.log('🔄 Admin received match update:', payload.new)
      console.log('🏑 MATCH CONTROL - Received update for match:', (payload.new as any).id)
      console.log('🏑 MATCH CONTROL - Booster update detected:', (payload.new as any).boosters)
      
      console.log('🏑🔄 Admin payload details:', {
        eventType: payload.eventType,
        hasOldBoosters: !!match.value?.boosters,
        hasNewBoosters: !!(payload.new as any).boosters,
        oldBoosters: match.value?.boosters,
        newBoosters: (payload.new as any).boosters
      })
      
      const oldMatch = match.value
      match.value = payload.new as any

      // Check for booster activations from users
      if (oldMatch?.boosters && (payload.new as any).boosters) {
        console.log('🔄 Checking for user booster activations...')
        detectUserBoosterActivations(oldMatch.boosters, (payload.new as any).boosters)
      }
      
      // Update match phase
      initializeMatchPhase()
    })
    .subscribe()
}

// Detect booster activations made by users
function detectUserBoosterActivations(oldBoosters: any, newBoosters: any) {
  console.log('🔍 Detecting user booster activations:', { oldBoosters, newBoosters })
  
  if (!oldBoosters || !newBoosters) {
    console.log('❌ Missing booster data for detection')
    return
  }
  
  // Check Team A boosters
  if (oldBoosters.teamA && newBoosters.teamA) {
    console.log(`🔍 Checking Team A boosters: ${oldBoosters.teamA.length} old vs ${newBoosters.teamA.length} new`)
    newBoosters.teamA.forEach((newBooster: any, index: number) => {
      const oldBooster = oldBoosters.teamA[index]
      console.log(`🔍 Team A booster ${index}:`, {
        oldActivated: oldBooster?.activated,
        newActivated: newBooster.activated,
        willTrigger: oldBooster && !oldBooster.activated && newBooster.activated,
        oldBooster: oldBooster,
        newBooster: newBooster
      })
      
      if (oldBooster && !oldBooster.activated && newBooster.activated) {
        console.log(`🚀 User activated Team A booster: ${newBooster.name || newBooster.title}`, newBooster)
        
        // If it's a timed booster, start the timer
        if (newBooster.duration && newBooster.duration > 0) {
          startBoosterTimer(newBooster, 'a', index)
        }
      }
    })
  }
  
  // Check Team B boosters  
  if (oldBoosters.teamB && newBoosters.teamB) {
    console.log(`🔍 Checking Team B boosters: ${oldBoosters.teamB.length} old vs ${newBoosters.teamB.length} new`)
    newBoosters.teamB.forEach((newBooster: any, index: number) => {
      const oldBooster = oldBoosters.teamB[index]
      console.log(`🔍 Team B booster ${index}:`, {
        oldActivated: oldBooster?.activated,
        newActivated: newBooster.activated,
        willTrigger: oldBooster && !oldBooster.activated && newBooster.activated,
        oldBooster: oldBooster,
        newBooster: newBooster
      })
      
      if (oldBooster && !oldBooster.activated && newBooster.activated) {
        console.log(`🚀 User activated Team B booster: ${newBooster.name || newBooster.title}`, newBooster)
        
        // If it's a timed booster, start the timer
        if (newBooster.duration && newBooster.duration > 0) {
          startBoosterTimer(newBooster, 'b', index)
        }
      }
    })
  }
}

// Maddie timer management functions
function startMaddieTimer(maddie: any) {
  console.log('🕐 Starting maddie timer in match control...', { maddie, duration: maddie.duration })
  
  // Clear any existing maddie timer
  clearMaddieTimer()
  
  if (!maddie.duration || maddie.duration <= 0) {
    console.log('⚠️ Maddie has no duration, skipping timer')
    return
  }
  
  const endTime = Date.now() + (maddie.duration * 1000) // Convert seconds to milliseconds
  
  activeMaddieTimer.value = {
    maddie: maddie,
    endTime: endTime,
    remainingTime: maddie.duration
  }
  
  console.log(`🕐 Started maddie timer: ${maddie.duration} seconds`)
  
  // Update timer every second
  const intervalId = setInterval(() => {
    if (activeMaddieTimer.value) {
      const now = Date.now()
      const remaining = Math.max(0, Math.ceil((activeMaddieTimer.value.endTime - now) / 1000))
      
      activeMaddieTimer.value.remainingTime = remaining
      
      console.log(`⏰ Maddie timer: ${remaining}s remaining`)
      
      if (remaining <= 0) {
        console.log('🚫 Maddie timer expired in match control')
        clearMaddieTimer()
      }
    } else {
      clearInterval(intervalId)
    }
  }, 1000)
  
  activeMaddieTimer.value.intervalId = intervalId
}

function clearMaddieTimer() {
  console.log('🧹 Clearing maddie timer in match control')
  if (activeMaddieTimer.value?.intervalId) {
    clearInterval(activeMaddieTimer.value.intervalId)
  }
  activeMaddieTimer.value = null
}

// Format maddie time for display
const formatMaddieTime = (seconds: number): string => {
  if (seconds <= 0) return '0:00'
  const mins = Math.floor(seconds / 60)
  const secs = seconds % 60
  return `${mins}:${secs.toString().padStart(2, '0')}`
}

// Clean up timers when component unmounts
function clearAllBoosterTimers() {
  Object.keys(activeBoosterTimers.value).forEach(timerKey => {
    clearBoosterTimer(timerKey)
  })
}

onMounted(async () => {
  loading.value = true
  
  // Reset all button states to prevent stuck states from previous sessions
  buttonStates.value = {
    play: false,
    pause: false,
    finish: false,
    spinners: false
  }
  console.log('🔄 Button states reset on mount')
  
  try {
    await Promise.all([loadMatch(), loadTeams(), loadBoostersAndMaddies()])
    
    // Setup real-time subscriptions after match is loaded
    setupRealtimeSubscription()
    
    // Start timers if match is active
    if (match.value?.status === 'active') {
      startTimer()
      startPenaltyTimer()
    }
  } catch (error) {
    console.error('❌ CRITICAL: Failed to initialize Match Control:', error)
    alert('Failed to load match data. Please refresh the page or contact support.')
  } finally {
    // ALWAYS set loading to false, even if errors occurred
    loading.value = false
    console.log('✅ Match Control initialization complete (loading state cleared)')
  }
})

onUnmounted(() => {
  stopTimer()
  stopPenaltyTimer()
  clearAllBoosterTimers()
  
  // Clean up score update timeouts
  Object.values(scoreUpdateTimeouts.value).forEach(timeoutId => {
    clearTimeout(timeoutId)
  })
  
  // Clean up PC update timeouts
  Object.values(pcUpdateTimeouts.value).forEach(timeoutId => {
    clearTimeout(timeoutId)
  })
  
  // Clean up button watchdog timers
  Object.values(buttonWatchdogTimers.value).forEach(timeoutId => {
    clearTimeout(timeoutId)
  })
  
  // Clean up subscription
  if (matchSubscription) {
    matchSubscription.unsubscribe()
  }
})
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-blue-900 via-blue-800 to-indigo-900">
    <div class="container mx-auto px-4 py-8">
      <div v-if="loading" class="text-center py-16">
        <div class="text-4xl font-bold text-white animate-pulse">{{ $t('matchControl.loading') }}</div>
      </div>

      <div v-else-if="!match" class="text-center py-16">
        <div class="text-4xl font-bold text-white mb-4">{{ $t('matchControl.notFound.title') }}</div>
        <RouterLink to="/admin" class="btn btn-primary">
          {{ $t('matchControl.notFound.backButton') }}
        </RouterLink>
      </div>

      <div v-else>
        <!-- Header -->
        <div class="flex justify-between items-center mb-8">
          <div>
            <h1 class="text-4xl font-bold text-white mb-2">{{ $t('matchControl.title') }}</h1>
            <p class="text-blue-100">
              {{ teamA?.name || 'Team A' }} vs {{ teamB?.name || 'Team B' }}
            </p>
          </div>
          <div class="flex gap-2">
            <button 
              @click="showStatsDialog = true" 
              class="btn btn-info gap-2"
            >
              📊 Match Stats
            </button>
            <RouterLink to="/admin" class="btn btn-secondary">
              {{ $t('matchControl.backToAdmin') }}
            </RouterLink>
          </div>
        </div>

        <!-- Match Not Initialized State -->
        <div v-if="match.status === 'pending' && !initialized" class="text-center py-16">
          <div class="text-3xl font-bold text-white mb-4">{{ $t('matchControl.setup.title') }}</div>
          <div class="text-blue-200 mb-8">
            {{ $t('matchControl.setup.description') }}
          </div>
          <button 
            @click="() => { console.log('🖱️ Initialize button clicked!'); initializeMatch(); }"
            class="btn bg-gradient-to-r from-green-500 to-blue-500 hover:from-green-600 hover:to-blue-600 text-white font-bold px-8 py-4 text-xl disabled:opacity-50 disabled:cursor-not-allowed"
            :disabled="!match || match.status !== 'pending' || initializing"
          >
            <span v-if="initializing" class="mr-2">⏳</span>
            <span v-else class="mr-2">🏑</span>
            {{ initializing ? 'Initializing...' : $t('matchControl.setup.initializeButton') }}
            <span v-if="match?.status !== 'pending'" class="text-xs block">
              (Status: {{ match?.status || 'loading...' }})
            </span>
          </button>
        </div>

        <!-- Main Control Panel -->
        <div v-else class="grid lg:grid-cols-3 gap-8">
          <!-- Team A Controls -->
          <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
            <h2 class="text-2xl font-bold text-blue-300 mb-6 text-center">
              {{ teamA?.name || 'Team A' }}
            </h2>
            
            <!-- Score Control -->
            <div class="text-center mb-6">
              <div class="text-6xl font-bold text-white mb-4">
                {{ match.score_a }}
              </div>
              <div class="flex justify-center space-x-2">
                <button @click="updateScore('a', -1)" class="btn btn-danger">-1</button>
                <button @click="updateScore('a', 1)" class="btn btn-success">+1</button>
              </div>
            </div>

            <!-- PC Control -->
            <div class="text-center mb-6">
              <div class="text-lg font-semibold text-white mb-2">Penalty Corners</div>
              <div class="text-4xl font-bold text-yellow-300 mb-3">
                {{ match.pc_a || 0 }}
              </div>
              <div class="flex justify-center space-x-2">
                <button @click="updatePC('a', -1)" class="btn btn-sm btn-warning">-1</button>
                <button @click="updatePC('a', 1)" class="btn btn-sm btn-warning">+1</button>
              </div>
            </div>

            <!-- Active Penalties -->
            <div class="mb-6">
              <h3 class="text-lg font-semibold text-white mb-3">{{ $t('matchControl.penalties.title') }}</h3>
              <div v-if="getActivePenaltiesForTeam('a').length > 0" class="space-y-2">
                <div 
                  v-for="penalty in getActivePenaltiesForTeam('a')" 
                  :key="penalty.playerId"
                  class="text-xs px-3 py-2 rounded-lg text-center font-bold"
                  :class="{
                    'bg-yellow-500 text-black': penalty.type === 'yellow',
                    'bg-green-600 text-white': penalty.type === 'green',
                    'bg-red-600 text-white': penalty.type === 'red'
                  }"
                >
                  #{{ penalty.playerNumber }} {{ penalty.playerName }}<br>
                  {{ penalty.type.toUpperCase() }} - {{ penalty.timeRemaining }}
                </div>
              </div>
              <div v-else class="text-sm text-blue-200 italic text-center py-4">
                {{ $t('matchControl.penalties.noPenalties') }}
              </div>
              <div class="text-xs text-blue-300 mt-2 text-center">
                {{ $t('matchControl.penalties.total') }}: {{ $t('matchControl.penalties.yellow') }}:{{ match.cards?.team_a?.yellow || 0 }} {{ $t('matchControl.penalties.green') }}:{{ match.cards?.team_a?.green || 0 }} {{ $t('matchControl.penalties.red') }}:{{ match.cards?.team_a?.red || 0 }}
              </div>
            </div>

            <!-- Team A Boosters -->
            <div v-if="match.boosters?.teamA?.filter((b: any) => !b.expired)?.length > 0" class="mb-6">
              <h3 class="text-lg font-semibold text-white mb-3">{{ $t('matchControl.boosters.title') }}</h3>
              <div class="space-y-2">
                <div 
                  v-for="(booster, index) in match.boosters.teamA" 
                  :key="`team-a-booster-${index}`"
                  v-show="!booster.expired"
                  class="bg-blue-600/20 rounded-lg p-3 border border-blue-400/40 shadow-lg transition-all duration-300"
                  :class="booster.activated ? 'ring-2 ring-green-400 bg-green-600/20' : ''"
                >
                  <div class="flex justify-between items-center">
                    <div class="flex-1">
                      <div class="text-sm font-bold flex items-center">
                        <span class="text-lg mr-2">{{ booster.icon }}</span>
                        <span>{{ booster.name }}</span>
                        <span v-if="booster.activated && !booster.expired" class="ml-2 text-xs bg-green-500 px-2 py-1 rounded-full animate-pulse">{{ $t('matchControl.boosters.active') }}</span>
                        <span v-else-if="!booster.activated" class="ml-2 text-xs bg-blue-500 px-2 py-1 rounded-full">{{ $t('matchControl.boosters.ready') }}</span>
                      </div>
                      <div class="text-xs text-blue-200 mt-1">{{ booster.description }}</div>
                    </div>
                    <button 
                      v-if="!booster.activated && !booster.expired && (match.status === 'active' || match.status === 'pending')"
                      @click="activateTeamBooster('a', index)"
                      class="btn-xs bg-green-600 hover:bg-green-700 text-white ml-2 animate-pulse"
                    >
                      {{ $t('matchControl.boosters.activate') }}
                    </button>
                    <!-- Finish button for instant boosters -->
                    <button 
                      v-else-if="booster.activated && !booster.expired && (!booster.duration || booster.duration === 0)"
                      @click="finishInstantBooster('a', index)"
                      class="btn-xs bg-orange-600 hover:bg-orange-700 text-white ml-2"
                      title="Finish instant booster"
                    >
                      Finish
                    </button>
                    <span v-else-if="booster.activated && !booster.expired" class="text-green-400 text-xs ml-2 animate-bounce">{{ $t('matchControl.boosters.live') }}</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- Players with Card Controls -->
            <div>
              <h3 class="text-lg font-semibold text-white mb-3">Players</h3>
              <div class="space-y-2 max-h-64 overflow-y-auto">
                <div 
                  v-for="player in teamA?.players || []" 
                  :key="player.name"
                  class="bg-white/5 rounded p-3"
                >
                  <!-- Player Info -->
                  <div class="flex justify-between items-center mb-2">
                    <div>
                      <span class="text-white font-medium">{{ player.name }} (#{{ player.number }})</span>
                      <div class="text-xs text-blue-300">{{ player.position }}</div>
                    </div>
                  </div>
                  
                  <!-- Active Penalty Display -->
                  <div v-if="getPlayerPenalty('a', player)" class="mb-2">
                    <div 
                      class="text-xs px-2 py-1 rounded text-center font-bold"
                      :class="{
                        'bg-yellow-500 text-black': getPlayerPenalty('a', player)?.type === 'yellow',
                        'bg-green-500 text-white': getPlayerPenalty('a', player)?.type === 'green',
                        'bg-red-500 text-white': getPlayerPenalty('a', player)?.type === 'red'
                      }"
                    >
                      {{ getPlayerPenalty('a', player)?.type.toUpperCase() }} CARD - 
                      {{ formatPenaltyTime(getPlayerPenalty('a', player)?.time_remaining || 0) }}
                    </div>
                  </div>
                  
                  <!-- Card Buttons -->
                  <div class="grid grid-cols-3 gap-1">
                    <button 
                      @click="addCardToPlayer('a', player, 'yellow')"
                      class="btn-xs bg-yellow-500 hover:bg-yellow-600 text-black text-xs"
                    >
                      Y
                    </button>
                    <button 
                      @click="addCardToPlayer('a', player, 'green')"
                      class="btn-xs bg-green-500 hover:bg-green-600 text-white text-xs"
                    >
                      G
                    </button>
                    <button 
                      @click="addCardToPlayer('a', player, 'red')"
                      class="btn-xs bg-red-500 hover:bg-red-600 text-white text-xs"
                    >
                      R
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Timer & Match Controls -->
          <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
            <h2 class="text-2xl font-bold text-white mb-6 text-center">Match Control</h2>
            
            <!-- Timer Display -->
            <div class="text-center mb-8">
              <!-- Phase Information -->
              <div class="mb-3">
                <div class="text-2xl font-bold text-blue-200 mb-2">
                  {{ currentPhaseLabel }}
                </div>
                <div v-if="currentPhase !== 'finished'" class="text-lg text-white/80">
                  {{ formatTime(phaseTimeLeft) }} remaining
                </div>
              </div>
              
              <!-- Total Match Time -->
              <div class="text-6xl font-mono font-bold text-yellow-400 mb-2">
                {{ formatTime(match.time_left) }}
              </div>
              <div class="text-sm text-white/60 mb-4">
                Total Match Time
              </div>
              
              <!-- Match Status -->
              <div 
                class="px-4 py-2 rounded-full text-white font-bold text-xl inline-block"
                :class="{
                  'bg-green-500': match.status === 'active',
                  'bg-yellow-500': match.status === 'paused',
                  'bg-red-500': match.status === 'finished',
                  'bg-gray-500': match.status === 'pending'
                }"
              >
                {{ match.status.toUpperCase() }}
              </div>
            </div>

            <!-- Timer Controls -->
            <div class="grid grid-cols-2 gap-3 mb-6">
              <button 
                v-if="match.status !== 'active'"
                @click="playMatch" 
                :disabled="buttonStates.play"
                class="btn btn-success"
                :class="{ 'opacity-50 cursor-not-allowed': buttonStates.play }"
              >
                <span v-if="buttonStates.play">⏳</span>
                <span v-else>▶️</span>
                {{ buttonStates.play ? 'Starting...' : 'Play' }}
              </button>
              <button 
                v-else
                @click="pauseMatch" 
                :disabled="buttonStates.pause"
                class="btn btn-warning"
                :class="{ 'opacity-50 cursor-not-allowed': buttonStates.pause }"
              >
                <span v-if="buttonStates.pause">⏳</span>
                <span v-else>⏸️</span>
                {{ buttonStates.pause ? 'Pausing...' : 'Pause' }}
              </button>
              
              <!-- Resume after booster execution button -->
              <button 
                v-if="match.status === 'paused' && match.special_state"
                @click="resumeAfterBooster" 
                class="btn bg-green-600 hover:bg-green-700 animate-pulse"
              >
                ▶️ Resume After Booster
              </button>
              
              <button 
                @click="finishMatch" 
                :disabled="buttonStates.finish"
                class="btn btn-danger"
                :class="{ 'opacity-50 cursor-not-allowed': buttonStates.finish }"
              >
                <span v-if="buttonStates.finish">⏳</span>
                <span v-else>⏹️</span>
                {{ buttonStates.finish ? 'Finishing...' : 'Finish' }}
              </button>
              
              <button @click="resetTimer" class="btn btn-secondary col-span-2">
                🔄 Reset Timer (30:00)
              </button>
              
              <button 
                v-if="match.status === 'pending' && !initialized"
                @click="initializeMatch" 
                class="btn btn-primary col-span-2"
              >
                🚀 Initialize Match
              </button>
              
              <button 
                v-if="(match.status === 'active' || match.status === 'pending') && (!match.boosters?.teamA?.length) && (!match.boosters?.teamB?.length)"
                @click="startBoosterSelection" 
                :disabled="buttonStates.spinners"
                class="btn bg-gradient-to-r from-purple-500 to-pink-500 hover:from-purple-600 hover:to-pink-600 col-span-2 animate-pulse"
                :class="{ 'opacity-50 cursor-not-allowed': buttonStates.spinners }"
              >
                <span v-if="buttonStates.spinners">⏳</span>
                <span v-else>🎰</span>
                {{ buttonStates.spinners ? 'Starting Casino...' : 'Spin Casino Boosters' }}
              </button>
              
              <div v-else-if="match.boosters?.teamA?.length > 0 || match.boosters?.teamB?.length > 0" class="col-span-2 text-center text-green-400 text-sm">
                ✅ Boosters already assigned
              </div>
            </div>

            <!-- Special Effects -->
            <div class="space-y-4">
              <div>
                <h3 class="text-lg font-semibold text-white mb-3">Special Effects</h3>
                
                <!-- Current Maddie Status -->
                <div v-if="match.maddie" class="mb-3 p-3 bg-purple-600/80 rounded-lg border border-purple-400">
                  <div class="text-center">
                    <div class="text-2xl mb-1">
                      {{ typeof match.maddie === 'object' ? (match.maddie.icon || '🎪') : '🎪' }}
                    </div>
                    <div class="text-sm font-semibold text-purple-100">
                      {{ typeof match.maddie === 'object' ? (match.maddie.name || match.maddie.title || 'Special Effect') : 'MADDIE ACTIVE!' }}
                    </div>
                    <div v-if="typeof match.maddie === 'object' && match.maddie.countdown" class="text-xs text-purple-200 animate-pulse">
                      🕐 Countdown Active
                    </div>
                    <div v-else-if="typeof match.maddie === 'object' && match.maddie.activated" class="text-xs text-purple-200 animate-pulse">
                      ✨ ACTIVE
                    </div>
                    <button 
                      @click="deactivateMaddie()"
                      class="mt-2 px-4 py-2 bg-red-600 hover:bg-red-700 text-white text-sm rounded-lg transition-colors"
                    >
                      ❌ Deactivate Maddie
                    </button>
                  </div>
                </div>

                <!-- Maddie Timer Display -->
                <div v-if="match.maddie && activeMaddieTimer && typeof match.maddie === 'object' && match.maddie.activated" class="mb-3 p-3 bg-orange-600/80 rounded-lg border border-orange-400">
                  <div class="text-center">
                    <div class="text-lg font-bold text-orange-100">
                      ⏱️ {{ formatMaddieTime(activeMaddieTimer.remainingTime) }}
                    </div>
                    <div class="text-xs text-orange-200">
                      Maddie Time Remaining
                    </div>
                  </div>
                </div>
                
                <!-- Maddie Selection -->
                <div v-if="!match.maddie" class="space-y-2">
                  <h4 class="text-sm font-semibold text-gray-300">Select Maddie Effect:</h4>
                  <div class="grid grid-cols-1 gap-2">
                    <button 
                      v-for="maddie in availableMaddies"
                      :key="maddie.id"
                      @click="triggerMaddie(maddie)"
                      class="flex items-center justify-center space-x-2 p-3 bg-purple-600/50 hover:bg-purple-600/70 rounded-lg border border-purple-400/50 hover:border-purple-400 transition-all"
                    >
                      <span class="text-xl">{{ maddie.icon || '🎪' }}</span>
                      <span class="text-sm font-medium text-purple-100">{{ maddie.title || maddie.name }}</span>
                    </button>
                  </div>
                  
                  <!-- Legacy Button (fallback) -->
                  <button 
                    @click="triggerMaddie()"
                    class="w-full btn btn-primary text-sm"
                  >
                    🎪 Classic Maddie Effect
                  </button>
                </div>
                
                <!-- Reset Button -->
                <button 
                  v-if="match.maddie"
                  @click="updateMatch({ maddie: false })"
                  class="w-full btn bg-gray-600 hover:bg-gray-700 text-white text-sm"
                >
                  🔄 Reset Maddie
                </button>
              </div>
              


            </div>
          </div>

          <!-- Team B Controls -->
          <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
            <h2 class="text-2xl font-bold text-red-300 mb-6 text-center">
              {{ teamB?.name || 'Team B' }}
            </h2>
            
            <!-- Score Control -->
            <div class="text-center mb-6">
              <div class="text-6xl font-bold text-white mb-4">
                {{ match.score_b }}
              </div>
              <div class="flex justify-center space-x-2">
                <button @click="updateScore('b', -1)" class="btn btn-danger">-1</button>
                <button @click="updateScore('b', 1)" class="btn btn-success">+1</button>
              </div>
            </div>

            <!-- PC Control -->
            <div class="text-center mb-6">
              <div class="text-lg font-semibold text-white mb-2">Penalty Corners</div>
              <div class="text-4xl font-bold text-yellow-300 mb-3">
                {{ match.pc_b || 0 }}
              </div>
              <div class="flex justify-center space-x-2">
                <button @click="updatePC('b', -1)" class="btn btn-sm btn-warning">-1</button>
                <button @click="updatePC('b', 1)" class="btn btn-sm btn-warning">+1</button>
              </div>
            </div>

            <!-- Active Penalties -->
            <div class="mb-6">
              <h3 class="text-lg font-semibold text-white mb-3">Active Penalties</h3>
              <div v-if="getActivePenaltiesForTeam('b').length > 0" class="space-y-2">
                <div 
                  v-for="penalty in getActivePenaltiesForTeam('b')" 
                  :key="penalty.playerId"
                  class="text-xs px-3 py-2 rounded-lg text-center font-bold"
                  :class="{
                    'bg-yellow-500 text-black': penalty.type === 'yellow',
                    'bg-green-600 text-white': penalty.type === 'green',
                    'bg-red-600 text-white': penalty.type === 'red'
                  }"
                >
                  #{{ penalty.playerNumber }} {{ penalty.playerName }}<br>
                  {{ penalty.type.toUpperCase() }} - {{ penalty.timeRemaining }}
                </div>
              </div>
              <div v-else class="text-sm text-red-200 italic text-center py-4">
                No active penalties
              </div>
              <div class="text-xs text-red-300 mt-2 text-center">
                Total: Y:{{ match.cards?.team_b?.yellow || 0 }} G:{{ match.cards?.team_b?.green || 0 }} R:{{ match.cards?.team_b?.red || 0 }}
              </div>
            </div>

            <!-- Team B Boosters -->
            <div v-if="match.boosters?.teamB?.filter((b: any) => !b.expired)?.length > 0" class="mb-6">
              <h3 class="text-lg font-semibold text-white mb-3">🎯 Active Boosters</h3>
              <div class="space-y-2">
                <div 
                  v-for="(booster, index) in match.boosters.teamB" 
                  :key="`team-b-booster-${index}`"
                  v-show="!booster.expired"
                  class="bg-red-600/20 rounded-lg p-3 border border-red-400/40 shadow-lg transition-all duration-300"
                  :class="booster.activated ? 'ring-2 ring-green-400 bg-green-600/20' : ''"
                >
                  <div class="flex justify-between items-center">
                    <div class="flex-1">
                      <div class="text-sm font-bold flex items-center">
                        <span class="text-lg mr-2">{{ booster.icon }}</span>
                        <span>{{ booster.name }}</span>
                        <span v-if="booster.activated && !booster.expired" class="ml-2 text-xs bg-green-500 px-2 py-1 rounded-full animate-pulse">ACTIVE</span>
                        <span v-else-if="!booster.activated" class="ml-2 text-xs bg-red-500 px-2 py-1 rounded-full">READY</span>
                      </div>
                      <div class="text-xs text-red-200 mt-1">{{ booster.description }}</div>
                    </div>
                    <button 
                      v-if="!booster.activated && !booster.expired && (match.status === 'active' || match.status === 'pending')"
                      @click="activateTeamBooster('b', index)"
                      class="btn-xs bg-green-600 hover:bg-green-700 text-white ml-2 animate-pulse"
                    >
                      Activate
                    </button>
                    <!-- Finish button for instant boosters -->
                    <button 
                      v-else-if="booster.activated && !booster.expired && (!booster.duration || booster.duration === 0)"
                      @click="finishInstantBooster('b', index)"
                      class="btn-xs bg-orange-600 hover:bg-orange-700 text-white ml-2"
                      title="Finish instant booster"
                    >
                      Finish
                    </button>
                    <span v-else-if="booster.activated && !booster.expired" class="text-green-400 text-xs ml-2 animate-bounce">🟢 LIVE</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- Players with Card Controls -->
            <div>
              <h3 class="text-lg font-semibold text-white mb-3">Players</h3>
              <div class="space-y-2 max-h-64 overflow-y-auto">
                <div 
                  v-for="player in teamB?.players || []" 
                  :key="player.name"
                  class="bg-white/5 rounded p-3"
                >
                  <!-- Player Info -->
                  <div class="flex justify-between items-center mb-2">
                    <div>
                      <span class="text-white font-medium">{{ player.name }} (#{{ player.number }})</span>
                      <div class="text-xs text-red-300">{{ player.position }}</div>
                    </div>
                  </div>
                  
                  <!-- Active Penalty Display -->
                  <div v-if="getPlayerPenalty('b', player)" class="mb-2">
                    <div 
                      class="text-xs px-2 py-1 rounded text-center font-bold"
                      :class="{
                        'bg-yellow-500 text-black': getPlayerPenalty('b', player)?.type === 'yellow',
                        'bg-green-500 text-white': getPlayerPenalty('b', player)?.type === 'green',
                        'bg-red-500 text-white': getPlayerPenalty('b', player)?.type === 'red'
                      }"
                    >
                      {{ getPlayerPenalty('b', player)?.type.toUpperCase() }} CARD - 
                      {{ formatPenaltyTime(getPlayerPenalty('b', player)?.time_remaining || 0) }}
                    </div>
                  </div>
                  
                  <!-- Card Buttons -->
                  <div class="grid grid-cols-3 gap-1">
                    <button 
                      @click="addCardToPlayer('b', player, 'yellow')"
                      class="btn-xs bg-yellow-500 hover:bg-yellow-600 text-black text-xs"
                    >
                      Y
                    </button>
                    <button 
                      @click="addCardToPlayer('b', player, 'green')"
                      class="btn-xs bg-green-500 hover:bg-green-600 text-white text-xs"
                    >
                      G
                    </button>
                    <button 
                      @click="addCardToPlayer('b', player, 'red')"
                      class="btn-xs bg-red-500 hover:bg-red-600 text-white text-xs"
                    >
                      R
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Quick Actions Bar -->
        <div class="mt-8 bg-white/10 backdrop-blur-sm rounded-xl p-4 border border-white/20">
          <div class="flex justify-center space-x-4 flex-wrap gap-2">
            <RouterLink 
              :to="`/scoreboard/${match.id}`" 
              target="_blank"
              class="btn btn-primary"
            >
              📺 Open Scoreboard
            </RouterLink>
            <button 
              @click="showStatsDialog = true"
              class="btn btn-secondary"
            >
              📊 Match Stats
            </button>
            <button 
              v-if="match.status !== 'pending'"
              @click="resetMatch"
              :disabled="resetting"
              class="btn bg-orange-600 hover:bg-orange-700 text-white border-orange-600 hover:border-orange-700 disabled:opacity-50 disabled:cursor-not-allowed"
              title="Reset match to initialization state"
            >
              {{ resetting ? '🔄 Resetting...' : '🔄 Reset Match' }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Booster Selection Modal -->
    <div 
      v-if="showBoosterSelection"
      class="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center z-50"
      @click="cancelBoosterSelection"
    >
      <div 
        class="bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900 rounded-2xl p-8 max-w-4xl w-full mx-4 border-2 border-purple-500/50"
        @click.stop
      >
        <div class="text-center mb-8">
          <h2 class="text-4xl font-bold text-white mb-2">🎰 Casino Booster Selection</h2>
          <p class="text-purple-200">Spin the slots to get 2 random boosters for each team!</p>
        </div>

        <!-- Current Phase Display -->
        <div class="mb-6 text-center">
          <div class="text-xl font-bold text-yellow-400">
            {{ getPhaseDescription() }}
          </div>
          <!-- Debug Info -->
          <div class="text-sm text-gray-400 mt-2">
            Phase: {{ boosterPhase }} | Spinning: {{ isSpinning }} | Available: {{ availableBoosters.length }}
          </div>
        </div>

        <!-- Slot Machine -->
        <div class="grid grid-cols-2 gap-8 mb-8">
          <!-- Team A Section -->
          <div 
            class="bg-white/10 rounded-xl p-6 text-center border-2"
            :class="{
              'border-blue-500 shadow-blue-500/50 shadow-lg': currentTeamSpinning === 'A' || (boosterPhase.includes('team-a') && !isSpinning),
              'border-blue-500/30': currentTeamSpinning !== 'A' && !boosterPhase.includes('team-a')
            }"
          >
            <h3 class="text-2xl font-bold text-blue-300 mb-4">{{ teamA?.name || 'Team A' }}</h3>
            
            <!-- Slot Machine for Team A -->
            <div 
              v-if="currentTeamSpinning === 'A' || (boosterPhase.includes('team-a') && boosterPhase !== 'ready')" 
              class="h-32 bg-black/30 rounded-lg mb-4 flex items-center justify-center relative overflow-hidden border-2 border-blue-400"
            >
              <div 
                class="text-6xl transition-all duration-100"
                :class="{ 'animate-spin': isSpinning && currentTeamSpinning === 'A' }"
              >
                {{ getCurrentSlotIcon() }}
              </div>
            </div>
            
            <!-- Selected Boosters Display -->
            <div v-if="selectedBoosters.teamA.length > 0" class="space-y-2">
              <div class="text-sm font-bold text-blue-300 mb-2">Selected Boosters:</div>
              <div 
                v-for="(booster, index) in selectedBoosters.teamA" 
                :key="index"
                class="bg-blue-500/20 rounded-lg p-3"
              >
                <div class="text-lg font-bold">{{ booster.icon }} {{ booster.name }}</div>
                <div class="text-sm text-blue-200">{{ booster.description }}</div>
              </div>
            </div>
          </div>

          <!-- Team B Section -->
          <div 
            class="bg-white/10 rounded-xl p-6 text-center border-2"
            :class="{
              'border-red-500 shadow-red-500/50 shadow-lg': currentTeamSpinning === 'B' || (boosterPhase.includes('team-b') && !isSpinning),
              'border-red-500/30': currentTeamSpinning !== 'B' && !boosterPhase.includes('team-b')
            }"
          >
            <h3 class="text-2xl font-bold text-red-300 mb-4">{{ teamB?.name || 'Team B' }}</h3>
            
            <!-- Slot Machine for Team B -->
            <div 
              v-if="currentTeamSpinning === 'B' || (boosterPhase.includes('team-b') && boosterPhase !== 'ready')" 
              class="h-32 bg-black/30 rounded-lg mb-4 flex items-center justify-center relative overflow-hidden border-2 border-red-400"
            >
              <div 
                class="text-6xl transition-all duration-100"
                :class="{ 'animate-spin': isSpinning && currentTeamSpinning === 'B' }"
              >
                {{ getCurrentSlotIcon() }}
              </div>
            </div>
            
            <!-- Selected Boosters Display -->
            <div v-if="selectedBoosters.teamB.length > 0" class="space-y-2">
              <div class="text-sm font-bold text-red-300 mb-2">Selected Boosters:</div>
              <div 
                v-for="(booster, index) in selectedBoosters.teamB" 
                :key="index"
                class="bg-red-500/20 rounded-lg p-3"
              >
                <div class="text-lg font-bold">{{ booster.icon }} {{ booster.name }}</div>
                <div class="text-sm text-red-200">{{ booster.description }}</div>
              </div>
            </div>
          </div>
        </div>

        <!-- Available Boosters Reference -->
        <div class="mb-8">
          <h3 class="text-xl font-bold text-white mb-4 text-center">Available Boosters</h3>
          <div class="grid grid-cols-5 gap-4">
            <div 
              v-for="booster in availableBoosters" 
              :key="booster.id"
              class="bg-white/5 rounded-lg p-3 text-center border border-purple-500/30"
            >
              <div class="text-2xl mb-2">{{ booster.icon }}</div>
              <div class="text-sm font-bold text-white">{{ booster.name }}</div>
              <div class="text-xs text-gray-300 mt-1">{{ booster.description }}</div>
            </div>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="flex justify-center space-x-4">
          <button 
            @click="cancelBoosterSelection"
            class="btn btn-secondary"
          >
            ❌ Cancel
          </button>
          
          <!-- Debug Reset Button (only show when spinning) -->
          <button 
            v-if="isSpinning"
            @click="isSpinning = false; currentTeamSpinning = null"
            class="btn bg-orange-600 hover:bg-orange-700 text-white"
            title="Debug: Force reset spinning state"
          >
            🔧 Reset Spin
          </button>
          
          <!-- Debug Log Button -->
          <button 
            @click="logBoosterState"
            class="btn bg-gray-600 hover:bg-gray-700 text-white text-sm"
            title="Debug: Log current state to console"
          >
            🔍 Debug
          </button>
          
          <!-- Debug Force Complete Button -->
          <button 
            v-if="boosterPhase !== 'complete'"
            @click="forceCompleteSelection"
            class="btn bg-yellow-600 hover:bg-yellow-700 text-white text-sm"
            title="Debug: Force complete selection with mock boosters"
          >
            ⚡ Force Complete
          </button>
          
          <button 
            v-if="boosterPhase !== 'complete'"
            @click="() => { if (!isSpinning) spinCurrentPhase() }"
            :disabled="isSpinning"
            class="btn bg-gradient-to-r from-purple-500 to-pink-500 hover:from-purple-600 hover:to-pink-600 text-white font-bold px-8"
            :class="{ 'opacity-50 cursor-not-allowed': isSpinning }"
          >
            {{ isSpinning ? '🎰 Spinning...' : getSpinButtonText() }}
          </button>
          
          <button 
            v-else
            @click="confirmBoosters"
            class="btn btn-success px-8"
          >
            ✅ Confirm Boosters
          </button>
        </div>
      </div>
    </div>
  </div>

  <!-- Stats Dialog Modal -->
  <div v-if="showStatsDialog" class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm" @click.self="showStatsDialog = false">
    <div class="relative w-full max-w-5xl max-h-[90vh] overflow-hidden bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900 rounded-2xl shadow-2xl border border-blue-500/30">
      
      <!-- Header -->
      <div class="flex items-center justify-between p-6 border-b border-blue-500/30 bg-gradient-to-r from-blue-600/20 to-purple-600/20">
        <h2 class="text-3xl font-bold text-white flex items-center gap-3">
          📊 Match Statistics
        </h2>
        <button @click="showStatsDialog = false" class="btn btn-circle btn-sm">✕</button>
      </div>

      <!-- Content -->
      <div class="p-6 overflow-y-auto max-h-[calc(90vh-88px)]">
        
        <!-- Stats Summary Cards -->
        <div class="grid grid-cols-2 gap-6 mb-6">
          <!-- Team A Stats -->
          <div v-if="teamAStats" class="bg-gradient-to-br from-blue-800/40 to-blue-900/40 rounded-xl p-6 border border-blue-500/30">
            <h3 class="text-2xl font-bold text-white mb-4">{{ teamA?.name || 'Team A' }}</h3>
            <div class="grid grid-cols-2 gap-4">
              <div class="bg-blue-900/50 rounded-lg p-3 text-center">
                <div class="text-4xl font-bold text-blue-300">{{ teamAStats.goals }}</div>
                <div class="text-sm text-blue-200 mt-1">Goals</div>
              </div>
              <div class="bg-blue-900/50 rounded-lg p-3 text-center">
                <div class="text-4xl font-bold text-purple-300">{{ teamAStats.penaltyCorners }}</div>
                <div class="text-sm text-purple-200 mt-1">Penalty Corners</div>
              </div>
              <div class="bg-blue-900/50 rounded-lg p-3 text-center">
                <div class="text-4xl font-bold text-green-300">{{ teamAStats.boosters }}</div>
                <div class="text-sm text-green-200 mt-1">Boosters</div>
              </div>
              <div class="bg-blue-900/50 rounded-lg p-3 text-center">
                <div class="text-4xl font-bold text-yellow-300">{{ teamAStats.yellowCards }}</div>
                <div class="text-sm text-yellow-200 mt-1">Yellow Cards</div>
              </div>
            </div>
          </div>

          <!-- Team B Stats -->
          <div v-if="teamBStats" class="bg-gradient-to-br from-purple-800/40 to-purple-900/40 rounded-xl p-6 border border-purple-500/30">
            <h3 class="text-2xl font-bold text-white mb-4">{{ teamB?.name || 'Team B' }}</h3>
            <div class="grid grid-cols-2 gap-4">
              <div class="bg-purple-900/50 rounded-lg p-3 text-center">
                <div class="text-4xl font-bold text-purple-300">{{ teamBStats.goals }}</div>
                <div class="text-sm text-purple-200 mt-1">Goals</div>
              </div>
              <div class="bg-purple-900/50 rounded-lg p-3 text-center">
                <div class="text-4xl font-bold text-blue-300">{{ teamBStats.penaltyCorners }}</div>
                <div class="text-sm text-blue-200 mt-1">Penalty Corners</div>
              </div>
              <div class="bg-purple-900/50 rounded-lg p-3 text-center">
                <div class="text-4xl font-bold text-green-300">{{ teamBStats.boosters }}</div>
                <div class="text-sm text-green-200 mt-1">Boosters</div>
              </div>
              <div class="bg-purple-900/50 rounded-lg p-3 text-center">
                <div class="text-4xl font-bold text-yellow-300">{{ teamBStats.yellowCards }}</div>
                <div class="text-sm text-yellow-200 mt-1">Yellow Cards</div>
              </div>
            </div>
          </div>
        </div>

        <!-- Filter Controls -->
        <div class="flex gap-4 mb-6 p-4 bg-slate-800/50 rounded-xl border border-slate-700">
          <div class="flex-1">
            <label class="text-sm text-slate-300 mb-2 block">Event Type</label>
            <select v-model="statsFilterType" class="select select-bordered w-full bg-slate-900/80 text-white">
              <option value="all">All Events</option>
              <option value="goal">⚽ Goals</option>
              <option value="penalty_corner">🏑 Penalty Corners</option>
              <option value="booster_activated">⚡ Boosters</option>
              <option value="maddie_activated">🎰 Maddies</option>
              <option value="card_issued">🟨 Cards</option>
              <option value="match_started">▶️ Match Started</option>
              <option value="match_paused">⏸️ Match Paused</option>
              <option value="match_resumed">▶️ Match Resumed</option>
              <option value="match_finished">🏁 Match Finished</option>
            </select>
          </div>
          <div class="flex-1">
            <label class="text-sm text-slate-300 mb-2 block">Team</label>
            <select v-model="statsFilterTeam" class="select select-bordered w-full bg-slate-900/80 text-white">
              <option value="all">All Teams</option>
              <option value="a">{{ teamA?.name || 'Team A' }}</option>
              <option value="b">{{ teamB?.name || 'Team B' }}</option>
            </select>
          </div>
        </div>

        <!-- Timeline -->
        <div class="bg-slate-800/50 rounded-xl border border-slate-700 p-4">
          <h3 class="text-xl font-bold text-white mb-4 flex items-center gap-2">
            📋 Event Timeline
            <span class="text-sm text-slate-400">({{ filteredTimeline.length }} events)</span>
          </h3>
          
          <div v-if="filteredTimeline.length === 0" class="text-center py-8 text-slate-400">
            No events found
          </div>
          
          <div v-else class="space-y-3 max-h-96 overflow-y-auto">
            <div 
              v-for="(event, index) in filteredTimeline" 
              :key="index"
              class="flex items-start gap-4 p-3 rounded-lg border transition-colors"
              :class="{
                'bg-blue-900/30 border-blue-500/30': event.team === 'a',
                'bg-purple-900/30 border-purple-500/30': event.team === 'b',
                'bg-slate-900/30 border-slate-500/30': !event.team
              }"
            >
              <div class="text-2xl">
                {{ event.type === 'goal' ? '⚽' : 
                   event.type === 'penalty_corner' ? '🏑' : 
                   event.type === 'booster_activated' ? '⚡' : 
                   event.type === 'maddie_activated' ? '🎰' : 
                   event.type === 'card_issued' ? '🟨' : 
                   event.type === 'match_started' ? '▶️' : 
                   event.type === 'match_paused' ? '⏸️' : 
                   event.type === 'match_resumed' ? '▶️' : '🏁' }}
              </div>
              <div class="flex-1">
                <div class="text-white font-semibold">
                  {{ event.type === 'goal' ? 'Goal Scored' :
                     event.type === 'penalty_corner' ? 'Penalty Corner' :
                     event.type === 'booster_activated' ? 'Booster Activated' :
                     event.type === 'maddie_activated' ? 'Maddie Activated' :
                     event.type === 'card_issued' ? `${(event as CardIssuedEvent).details.card_type.toUpperCase()} Card Issued` :
                     event.type === 'match_started' ? 'Match Started' :
                     event.type === 'match_paused' ? 'Match Paused' :
                     event.type === 'match_resumed' ? 'Match Resumed' : 'Match Finished' }}
                </div>
                <div class="text-sm text-slate-300 mt-1">
                  <span v-if="event.team === 'a'">{{ teamA?.name }}</span>
                  <span v-else-if="event.team === 'b'">{{ teamB?.name }}</span>
                  <span v-if="event.matchTime !== undefined" class="ml-2">
                    • Time: {{ formatTime(event.matchTime) }}
                  </span>
                </div>
                <div v-if="event.type === 'goal'" class="text-xs text-slate-400 mt-1">
                  Score: {{ (event as GoalEvent).details.score_a }} - {{ (event as GoalEvent).details.score_b }}
                  <span v-if="(event as GoalEvent).details.pc"> (from PC)</span>
                </div>
                <div v-else-if="event.type === 'penalty_corner'" class="text-xs text-slate-400 mt-1">
                  PC Count: {{ (event as PenaltyCornerEvent).details.pc_a }} - {{ (event as PenaltyCornerEvent).details.pc_b }}
                </div>
                <div v-else-if="event.type === 'booster_activated'" class="text-xs text-slate-400 mt-1">
                  {{ (event as BoosterActivatedEvent).details.booster_name }}
                </div>
                <div v-else-if="event.type === 'maddie_activated'" class="text-xs text-slate-400 mt-1">
                  {{ (event as MaddieActivatedEvent).details.maddie_name }}
                </div>
                <div v-else-if="event.type === 'card_issued'" class="text-xs text-slate-400 mt-1">
                  Player: {{ (event as CardIssuedEvent).details.player_name }} (#{{ (event as CardIssuedEvent).details.player_number }})
                </div>
              </div>
              <div class="text-xs text-slate-400 whitespace-nowrap">
                {{ new Date(event.timestamp).toLocaleTimeString() }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.btn-xs {
  padding: 0.25rem 0.5rem;
  border-radius: 0.375rem;
  font-size: 0.75rem;
  font-weight: 500;
  transition: background-color 0.2s;
  cursor: pointer;
  border: none;
}

/* Slot machine animations */
@keyframes spin {
  from { transform: rotateY(0deg); }
  to { transform: rotateY(360deg); }
}

.animate-spin {
  animation: spin 0.1s linear infinite;
}

/* Casino-style glow effects */
@keyframes glow {
  0%, 100% { box-shadow: 0 0 20px rgba(147, 51, 234, 0.5); }
  50% { box-shadow: 0 0 30px rgba(147, 51, 234, 0.8), 0 0 40px rgba(147, 51, 234, 0.6); }
}

.animate-pulse {
  animation: glow 2s ease-in-out infinite;
}

/* Slot machine border effect */
.border-slot {
  border: 3px solid;
  border-image: linear-gradient(45deg, #f59e0b, #ec4899, #8b5cf6) 1;
  animation: glow 1.5s ease-in-out infinite alternate;
}

/* Booster activation effects */
@keyframes booster-glow {
  0% { box-shadow: 0 0 10px rgba(34, 197, 94, 0.4); }
  50% { box-shadow: 0 0 20px rgba(34, 197, 94, 0.8), 0 0 30px rgba(34, 197, 94, 0.6); }
  100% { box-shadow: 0 0 10px rgba(34, 197, 94, 0.4); }
}

.booster-active {
  animation: booster-glow 1.5s ease-in-out infinite;
}
</style>