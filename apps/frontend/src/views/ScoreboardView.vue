<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useThemeStore } from '@/stores/theme'
import { supabase } from '@/lib/supabase'
import { SoundManager } from '@/lib/soundManager'

interface Match {
  id: string
  team_a: string
  team_b: string
  score_a: number
  score_b: number
  status: 'pending' | 'active' | 'paused' | 'finished'
  time_left: number
  maddie: boolean | any // Extended to support structured maddie data
  boosters: any
  cards: any
  player_penalties?: any
  booster_selection_active?: boolean
  booster_selection_phase?: string
  current_boosters?: {
    teamA: any[]
    teamB: any[]
  }
  // Match duration settings
  quarters_count?: number
  quarter_duration_minutes?: number
  break_duration_minutes?: number
  halftime_duration_minutes?: number
}

interface PlayerPenalty {
  playerId: string
  playerNumber: string
  playerName: string
  type: 'yellow' | 'green' | 'red'
  timeRemaining: string
}

interface Team {
  id: string
  name: string
  players: any[]
}

const { t } = useI18n()
const themeStore = useThemeStore()

const currentMatch = ref<Match | null>(null)
const teams = ref<Record<string, Team>>({})
const loading = ref(true)
const maddieFlash = ref(false)
const boosterActivation = ref<{
  active: boolean
  teamName: string
  boosterName: string
  boosterIcon: string
  teamColor: string
} | null>(null)

// Track maddie activation for visual effect
const maddieActivation = ref<{
  active: boolean
  maddieName: string
  maddieIcon: string
  maddieDescription?: string
  maddieDuration?: number
} | null>(null)

// Track booster countdown before activation
const boosterCountdown = ref<{
  active: boolean
  teamName: string
  boosterName: string
  boosterIcon: string
  teamColor: string
  countdown: number
  teamKey: 'teamA' | 'teamB'
  boosterIndex: number
} | null>(null)

// Track maddie countdown before activation
const maddieCountdown = ref<{
  active: boolean
  maddieName: string
  maddieIcon: string
  maddieDescription?: string
  maddieDuration?: number
  countdown: number
} | null>(null)

let countdownInterval: number | null = null
let maddieCountdownInterval: number | null = null

// Track timer intervals for cleanup
const activeTimerIntervals = ref<Record<string, number>>({})
let realtimeSubscription: any = null

// Track active booster timers for countdown
const activeBoosterTimers = ref<{[key: string]: {
  booster: any
  team: string
  endTime: number
  remainingTime: number
}}>({})

// Track active maddie timer
const activeMaddieTimer = ref<{
  maddie: any
  endTime: number
  remainingTime: number
} | null>(null)

let maddieTimerInterval: number | null = null

// Available boosters and maddies from database
const availableBoosters = ref<any[]>([])
const availableMaddies = ref<any[]>([])

// Match phase tracking
const currentPhase = ref<'quarter' | 'break' | 'halftime' | 'finished'>('quarter')
const currentPeriod = ref(1) // Current quarter/half number
const phaseTimeLeft = ref(0) // Time left in current phase
const totalMatchTime = ref(0)

// Local timer for smooth countdown
let localTimer: number | null = null
const lastSyncTime = ref<number>(0) // Timestamp of last database sync

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
      availableBoosters.value = boostersResult.data.map(booster => ({
        id: booster.id,
        name: booster.title,
        icon: booster.icon || '⚡',
        description: booster.description,
        duration: booster.duration
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

const teamA = computed(() => currentMatch.value ? teams.value[currentMatch.value.team_a] : null)
const teamB = computed(() => currentMatch.value ? teams.value[currentMatch.value.team_b] : null)

// Match duration settings with defaults
const matchSettings = computed(() => {
  if (!currentMatch.value) return null
  
  return {
    quarters_count: currentMatch.value.quarters_count || 4,
    quarter_duration_minutes: currentMatch.value.quarter_duration_minutes || 15,
    break_duration_minutes: currentMatch.value.break_duration_minutes || 2,
    halftime_duration_minutes: currentMatch.value.halftime_duration_minutes || 10
  }
})

const isHalfTimeGame = computed(() => {
  return matchSettings.value?.quarters_count === 2
})

const currentPhaseLabel = computed(() => {
  if (!matchSettings.value) return 'Game'
  
  switch (currentPhase.value) {
    case 'quarter':
      return isHalfTimeGame.value 
        ? `${currentPeriod.value}${currentPeriod.value === 1 ? 'st' : 'nd'} Half`
        : `${currentPeriod.value}${getOrdinalSuffix(currentPeriod.value)} Quarter`
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

function getOrdinalSuffix(num: number): string {
  const j = num % 10
  const k = num % 100
  if (j == 1 && k != 11) return 'st'
  if (j == 2 && k != 12) return 'nd'
  if (j == 3 && k != 13) return 'rd'
  return 'th'
}

const getActivePenalties = (teamKey: 'team_a' | 'team_b'): PlayerPenalty[] => {
  if (!currentMatch.value?.cards?.player_penalties?.[teamKey]) return []
  
  const penalties: PlayerPenalty[] = []
  const teamPenalties = currentMatch.value.cards.player_penalties[teamKey]
  const playerInfo = currentMatch.value.cards.player_info?.[teamKey] || {}
  
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
        const mins = Math.floor(seconds / 60)
        const secs = seconds % 60
        timeRemaining = `${mins}:${secs.toString().padStart(2, '0')}`
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

// Start local timer for smooth countdown between database updates
function startLocalTimer() {
  if (localTimer) {
    clearInterval(localTimer)
  }
  
  console.log('🔄 Starting scoreboard local timer')
  
  localTimer = setInterval(() => {
    if (currentMatch.value && currentMatch.value.status === 'active' && currentMatch.value.time_left > 0) {
      // Update local time
      currentMatch.value.time_left--
      
      // Update phase time
      if (phaseTimeLeft.value > 0) {
        phaseTimeLeft.value--
      }
      
      // Recalculate phase if needed
      calculateCurrentPhase()
      
      // Stop timer if time reaches 0
      if (currentMatch.value.time_left <= 0) {
        stopLocalTimer()
      }
    }
  }, 1000)
}

// Stop local timer
function stopLocalTimer() {
  if (localTimer) {
    console.log('🔄 Stopping scoreboard local timer')
    clearInterval(localTimer)
    localTimer = null
  }
}

// Synchronize with database update
function syncWithDatabaseUpdate(newTimeLeft: number) {
  if (currentMatch.value) {
    console.log('🔄 Syncing scoreboard timer with database update:', { 
      oldTime: currentMatch.value.time_left, 
      newTime: newTimeLeft 
    })
    
    // Update local time to match database
    currentMatch.value.time_left = newTimeLeft
    lastSyncTime.value = Date.now()
    
    // Recalculate phase timing
    calculateCurrentPhase()
    
    // Restart timer if match is active
    if (currentMatch.value.status === 'active') {
      startLocalTimer()
    } else {
      stopLocalTimer()
    }
  }
}

const getStatusColor = (status: string) => {
  switch (status) {
    case 'active': return 'bg-green-500'
    case 'paused': return 'bg-yellow-500'
    case 'finished': return 'bg-red-500'
    default: return 'bg-gray-500'
  }
}

const getStatusText = (status: string) => {
  switch (status) {
    case 'active': return t('scoreboard.statuses.active')
    case 'paused': return t('scoreboard.statuses.paused')
    case 'finished': return t('scoreboard.statuses.finished')
    default: return t('scoreboard.statuses.pending')
  }
}

const getBoosterSelectionPhaseText = () => {
  const phase = currentMatch.value?.boosters?.selection_phase
  if (!phase) return 'Preparing booster selection...'
  
  switch (phase) {
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
      return 'Booster selection in progress...'
  }
}

// Debug computed to track booster overlay display
const shouldShowBoosterOverlay = computed(() => {
  const boosters = currentMatch.value?.boosters
  const active = boosters?.selection_active
  const phase = boosters?.selection_phase
  
  // Debug booster data
  console.log('🎯 Booster data debug:', {
    hasMatch: !!currentMatch.value,
    boosters: boosters,
    // Confirmed boosters (after confirm button)
    teamA: boosters?.teamA,
    teamB: boosters?.teamB,
    // Selection boosters (during selection)
    current_teamA: boosters?.current_boosters?.teamA,
    current_teamB: boosters?.current_boosters?.teamB,
    teamA_length: boosters?.teamA?.length,
    teamB_length: boosters?.teamB?.length,
    current_teamA_length: boosters?.current_boosters?.teamA?.length,
    current_teamB_length: boosters?.current_boosters?.teamB?.length,
    active,
    phase
  })
  
  // Only show overlay if selection is explicitly active AND phase is not null
  // Include 'complete' phase so users can see results and confirm boosters
  const shouldShow = active === true && phase && phase !== null
  
  console.log('🎰 Scoreboard booster overlay check:', {
    hasMatch: !!currentMatch.value,
    boosters: !!boosters,
    active,
    phase,
    shouldShow,
    debug_conditions: {
      active_is_true: active === true,
      phase_exists: !!phase,
      phase_not_complete: phase !== 'complete',
      phase_not_null: phase !== null
    }
  })
  return shouldShow
})

// Force close booster overlay (debug function)
function forceCloseBoosterOverlay() {
  console.log('🎰 Force closing booster overlay')
  if (currentMatch.value?.boosters) {
    currentMatch.value.boosters.selection_active = false
  }
}

// Match phase management functions
function initializeMatchPhase() {
  if (!currentMatch.value || !matchSettings.value) return
  
  // Calculate total match time based on match settings
  const settings = matchSettings.value
  const quarterTimeSeconds = settings.quarter_duration_minutes * 60
  const breakTimeSeconds = settings.break_duration_minutes * 60
  const halftimeTimeSeconds = settings.halftime_duration_minutes * 60
  
  // Calculate total match time based on quarters and breaks
  const totalQuarterTime = settings.quarters_count * quarterTimeSeconds
  
  let totalBreakTime = 0
  if (settings.quarters_count === 2) {
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
  
  // Start or stop local timer based on match status
  if (currentMatch.value.status === 'active') {
    startLocalTimer()
  } else {
    stopLocalTimer()
  }
}

function calculateCurrentPhase() {
  if (!currentMatch.value || !matchSettings.value) return
  
  const timeElapsed = totalMatchTime.value - currentMatch.value.time_left
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

async function loadCurrentMatch() {
  try {
    console.log('📡 Loading current match...')
    
    // First priority: Active or paused matches
    const { data: activeMatches, error: activeError } = await supabase
      .from('matches')
      .select('*')
      .in('status', ['active', 'paused'])
      .limit(1)

    if (activeError) {
      console.error('Error loading active matches:', activeError)
    } else if (activeMatches && activeMatches.length > 0) {
      currentMatch.value = activeMatches[0]
      console.log('📡 Active/paused match loaded:', activeMatches[0].id)
      console.log('🚨 SCOREBOARD - Now watching match:', activeMatches[0].id)
      console.log('🚨 SCOREBOARD MATCH DETAILS:', {
        id: activeMatches[0].id,
        status: activeMatches[0].status,
        teamA: activeMatches[0].team_a,
        teamB: activeMatches[0].team_b
      })
      initializeMatchPhase()
      return
    }

    // Second priority: Initialized pending matches (have boosters, cards, or non-default scores/time)
    const { data: pendingMatches, error: pendingError } = await supabase
      .from('matches')
      .select('*')
      .eq('status', 'pending')
      .order('created_at', { ascending: false })

    if (pendingError) {
      console.error('Error loading pending matches:', pendingError)
    } else if (pendingMatches && pendingMatches.length > 0) {
      // Find the first initialized match (has been modified from defaults)
      const initializedMatch = pendingMatches.find(match => {
        // Check for actual meaningful modifications (not just cleared booster state)
        const hasConfirmedBoosters = (
          match.boosters?.teamA?.length > 0 || 
          match.boosters?.teamB?.length > 0
        )
        const hasCards = Object.keys(match.cards || {}).length > 0
        const hasScores = match.score_a > 0 || match.score_b > 0
        const hasModifiedTime = match.time_left !== 1800
        
        const hasBeenModified = hasConfirmedBoosters || hasCards || hasScores || hasModifiedTime
        
        console.log('📡 Checking match initialization:', {
          id: match.id,
          hasConfirmedBoosters,
          hasCards,
          hasScores,
          hasModifiedTime,
          hasBeenModified,
          boosters: match.boosters
        })
        
        return hasBeenModified
      })

      if (initializedMatch) {
        currentMatch.value = initializedMatch
        initializeMatchPhase()
        console.log('📡 Initialized pending match loaded:', {
          id: initializedMatch.id,
          team_a: initializedMatch.team_a,
          team_b: initializedMatch.team_b,
          status: initializedMatch.status,
          boosters: initializedMatch.boosters
        })
        console.log('🚨 SCOREBOARD - Now watching match:', initializedMatch.id)
        return
      }

      // Fallback to newest pending match if none are initialized
      currentMatch.value = pendingMatches[0]
      initializeMatchPhase()
      console.log('📡 Latest pending match loaded:', pendingMatches[0].id)
      console.log('🚨 SCOREBOARD - Now watching match:', pendingMatches[0].id)
    } else {
      console.log('📡 No matches found in database')
      currentMatch.value = null
    }
  } catch (error) {
    console.error('Error loading current match:', error)
    currentMatch.value = null
  }
}

async function loadTeams() {
  try {
    const { data, error } = await supabase
      .from('teams')
      .select('*')

    if (error) {
      console.error('Error loading teams:', error)
      return
    }

    const teamsMap: Record<string, Team> = {}
    data?.forEach(team => {
      teamsMap[team.id] = team
    })
    teams.value = teamsMap
  } catch (error) {
    console.error('Error loading teams:', error)
  }
}

function setupRealtimeSubscription() {
  console.log('🔧 setupRealtimeSubscription called', { 
    hasCurrentMatch: !!currentMatch.value, 
    matchId: currentMatch.value?.id,
    matchStatus: currentMatch.value?.status
  })
  
  if (!currentMatch.value) {
    console.log('❌ No current match - cannot set up subscription')
    return
  }
  
  console.log('🔧 Setting up ScoreboardView real-time subscription for match:', currentMatch.value.id)
  
  const channelName = `scoreboard_match_${currentMatch.value.id}`
  console.log('📡 Creating channel:', channelName)
  
  realtimeSubscription = supabase
    .channel(channelName)
    .on(
      'postgres_changes',
      {
        event: 'UPDATE',
        schema: 'public',
        table: 'matches',
        filter: `id=eq.${currentMatch.value.id}`
      },
      (payload) => {
        console.log('📡 *** SCOREBOARD RECEIVED UPDATE ***', payload)
          console.log('📡 Scoreboard received real-time update:', payload)
          console.log('📡 Payload details:', {
            eventType: payload.eventType,
            newId: (payload.new as any)?.id,
            currentMatchId: currentMatch.value?.id,
            willUpdate: payload.eventType === 'UPDATE' && currentMatch.value?.id === (payload.new as any)?.id
          })
          
          // DETAILED BOOSTER COMPARISON DEBUG
          console.log('🔍 DETAILED BOOSTER COMPARISON:')
          console.log('🔍 Old boosters structure:', JSON.stringify(currentMatch.value?.boosters, null, 2))
          console.log('🔍 New boosters structure:', JSON.stringify((payload.new as any).boosters, null, 2))
        
        if (payload.eventType === 'UPDATE') {
          console.log('🚨 SCOREBOARD - Received update for match:', payload.new.id)
          
          const oldMaddie = currentMatch.value?.maddie || false
          const oldBoosters = currentMatch.value?.boosters
          
          console.log('📡 Updating match state:', { 
            boosters: payload.new.boosters,
            selection_active: payload.new.boosters?.selection_active,
            selection_phase: payload.new.boosters?.selection_phase,
            teamA: payload.new.boosters?.teamA,
            teamB: payload.new.boosters?.teamB,
            oldBoosters: oldBoosters
          })
          
          // Detect booster activation before updating the match
          detectBoosterActivation(oldBoosters, payload.new.boosters)
          
          // Store old values for sync comparison
          const oldTimeLeft = currentMatch.value?.time_left || 0
          const oldStatus = currentMatch.value?.status
          
          currentMatch.value = payload.new as Match
          
          // Sync timer if time changed OR status changed
          if (currentMatch.value.time_left !== oldTimeLeft || currentMatch.value.status !== oldStatus) {
            syncWithDatabaseUpdate(currentMatch.value.time_left)
          } else {
            initializeMatchPhase()
          }
          
          const overlayShould = currentMatch.value?.boosters?.selection_active === true
          console.log('📡 Match state updated, overlay should be:', overlayShould)
          
          // Enhanced debugging for booster state changes
          if (payload.new.boosters) {
            console.log('📡 Booster state change detected:', {
              selection_active: payload.new.boosters.selection_active,
              selection_phase: payload.new.boosters.selection_phase,
              teamA_exists: !!payload.new.boosters.teamA,
              teamB_exists: !!payload.new.boosters.teamB,
              teamA_length: payload.new.boosters.teamA?.length || 0,
              teamB_length: payload.new.boosters.teamB?.length || 0
            })
          }
          
          // Detect maddie activation
          detectMaddieActivation(oldMaddie, currentMatch.value.maddie)
        }
      }
    )
    .subscribe((status) => {
      console.log('🔧 ScoreboardView subscription status:', status)
      if (status === 'SUBSCRIBED') {
        console.log('✅ ScoreboardView successfully subscribed to real-time updates')
      } else if (status === 'CHANNEL_ERROR') {
        console.error('❌ ScoreboardView subscription error')
      }
    })
}

function triggerMaddieFlash() {
  maddieFlash.value = true
  // Play sound effect
  playMaddieSound()
  
  setTimeout(() => {
    maddieFlash.value = false
  }, 1000)
}

function startBoosterCountdown(teamKey: 'teamA' | 'teamB', booster: any, teamName: string, boosterIndex: number) {
  console.log('🕐 Starting booster countdown...', { teamKey, booster, teamName, boosterIndex })
  
  // Clear any existing countdown
  if (countdownInterval) {
    clearInterval(countdownInterval)
    countdownInterval = null
  }
  
  // Set up countdown display
  boosterCountdown.value = {
    active: true,
    teamName: teamName,
    boosterName: booster.name,
    boosterIcon: booster.icon,
    teamColor: teamKey === 'teamA' ? 'blue' : 'red',
    countdown: 7,
    teamKey,
    boosterIndex
  }
  
  // Start countdown timer
  countdownInterval = setInterval(() => {
    if (boosterCountdown.value && boosterCountdown.value.countdown > 1) {
      boosterCountdown.value.countdown--
      console.log(`⏰ Booster countdown: ${boosterCountdown.value.countdown}`)
    } else {
      // Countdown finished - trigger actual activation
      console.log('🚀 Countdown finished - triggering booster activation!')
      clearInterval(countdownInterval!)
      countdownInterval = null
      
      if (boosterCountdown.value) {
        triggerBoosterActivation(
          boosterCountdown.value.teamKey,
          booster,
          boosterCountdown.value.teamName
        )
        boosterCountdown.value = null
      }
    }
  }, 1000)
}

function startMaddieCountdown(maddie: any) {
  console.log('🎪 Starting maddie countdown...', { maddie })
  
  // Clear any existing maddie countdown
  if (maddieCountdownInterval) {
    clearInterval(maddieCountdownInterval)
    maddieCountdownInterval = null
  }
  
  // Set up countdown display with detailed information
  maddieCountdown.value = {
    active: true,
    maddieName: maddie.name || maddie.title || 'Special Effect',
    maddieIcon: maddie.icon || '🎪',
    maddieDescription: maddie.description || maddie.subtitle || 'A special effect will be activated',
    maddieDuration: maddie.duration || null,
    countdown: 7
  }
  
  // Start countdown timer
  maddieCountdownInterval = setInterval(() => {
    if (maddieCountdown.value && maddieCountdown.value.countdown > 1) {
      maddieCountdown.value.countdown--
      console.log(`⏰ Maddie countdown: ${maddieCountdown.value.countdown}`)
    } else {
      // Countdown finished - trigger actual activation
      console.log('🚀 Maddie countdown finished - triggering maddie activation!')
      clearInterval(maddieCountdownInterval!)
      maddieCountdownInterval = null
      
      if (maddieCountdown.value) {
        triggerMaddieActivation(maddie)
        maddieCountdown.value = null
      }
    }
  }, 1000)
}

function triggerBoosterActivation(teamKey: 'teamA' | 'teamB', booster: any, teamName: string) {
  console.log('🎯 Booster activated!', { teamKey, booster, teamName })
  
  // Set up visual effect
  boosterActivation.value = {
    active: true,
    teamName: teamName,
    boosterName: booster.name,
    boosterIcon: booster.icon,
    teamColor: teamKey === 'teamA' ? 'blue' : 'red'
  }
  
  // Play booster activation sound
  playBoosterSound(booster)
  
  // Handle different booster types
  if (booster.duration && booster.duration > 0) {
    // Timed booster - add countdown timer
    const baseTimerKey = `${teamKey}_${booster.id}`
    
    // Check if timer already exists for this booster to prevent duplicates
    const existingTimer = Object.keys(activeBoosterTimers.value).find(key => key.startsWith(baseTimerKey))
    if (existingTimer) {
      console.log(`⚠️ Timer already exists for ${booster.name}, skipping duplicate creation`)
      return
    }
    
    const timerKey = `${baseTimerKey}_${Date.now()}`
    const endTime = Date.now() + (booster.duration * 60 * 1000) // Convert minutes to milliseconds
    
    activeBoosterTimers.value[timerKey] = {
      booster,
      team: teamKey,
      endTime,
      remainingTime: booster.duration * 60 // seconds
    }
    
    console.log(`🕐 Started timer for ${booster.name}: ${booster.duration} minutes`)
    
    // Update timer every second
    const timerInterval = setInterval(async () => {
      const timer = activeBoosterTimers.value[timerKey]
      if (!timer) {
        clearInterval(timerInterval)
        delete activeTimerIntervals.value[timerKey]
        return
      }
      
      const now = Date.now()
      timer.remainingTime = Math.max(0, Math.floor((timer.endTime - now) / 1000))
      
      if (timer.remainingTime <= 0) {
        console.log(`⏰ Timer expired for ${timer.booster.name}`)
        
        // Mark booster as expired in database
        await markBoosterAsExpired(timer.team, timer.booster.id)
        
        delete activeBoosterTimers.value[timerKey]
        clearInterval(timerInterval)
        delete activeTimerIntervals.value[timerKey]
      }
    }, 1000)
    
    // Track the interval for cleanup
    activeTimerIntervals.value[timerKey] = timerInterval
  } else {
    // Instant booster - special handling for stroke/timeout boosters
    console.log(`⚡ Instant booster activated: ${booster.name}`)
    
    if (booster.id === 'coach_stroke') {
      // For coach stroke, we might want to pause the game timer
      // This would need to be coordinated with match control
      console.log('🎯 Coach stroke activated - game should pause for execution')
    }
  }
  
  // Hide visual effect after 3 seconds
  setTimeout(() => {
    if (boosterActivation.value) {
      boosterActivation.value.active = false
      setTimeout(() => {
        boosterActivation.value = null
      }, 500) // Allow fade out animation
    }
  }, 3000)
}

function triggerMaddieActivation(maddie: any) {
  console.log('🎪 Maddie activated!', { maddie })
  
  // Set up visual effect with detailed information
  maddieActivation.value = {
    active: true,
    maddieName: maddie.name || maddie.title || 'Special Effect',
    maddieIcon: maddie.icon || '🎪',
    maddieDescription: maddie.description || maddie.subtitle || 'A special effect has been activated',
    maddieDuration: maddie.duration || null
  }
  
  // Trigger flash effect (keeping existing behavior)
  maddieFlash.value = true
  
  // Play maddie activation sound
  playMaddieSound()
  
  // Hide flash effect after 1 second (existing behavior)
  setTimeout(() => {
    maddieFlash.value = false
  }, 1000)
  
  // Hide visual effect after 4 seconds (longer than flash for full announcement)
  setTimeout(() => {
    if (maddieActivation.value) {
      maddieActivation.value.active = false
      setTimeout(() => {
        maddieActivation.value = null
      }, 500) // Allow fade out animation
    }
  }, 4000)

  // Start maddie duration timer if the maddie has a duration
  if (maddie.duration && maddie.duration > 0) {
    startMaddieTimer(maddie)
  }
}

function startMaddieTimer(maddie: any) {
  console.log('🕐 Starting maddie timer...', { maddie, duration: maddie.duration })
  
  // Clear any existing maddie timer
  if (maddieTimerInterval) {
    clearInterval(maddieTimerInterval)
    maddieTimerInterval = null
  }
  
  const endTime = Date.now() + (maddie.duration * 1000) // Convert seconds to milliseconds
  
  activeMaddieTimer.value = {
    maddie: maddie,
    endTime: endTime,
    remainingTime: maddie.duration
  }
  
  console.log(`🕐 Started maddie timer: ${maddie.duration} seconds`)
  
  // Update timer every second
  maddieTimerInterval = setInterval(() => {
    if (activeMaddieTimer.value) {
      const now = Date.now()
      const remaining = Math.max(0, Math.ceil((activeMaddieTimer.value.endTime - now) / 1000))
      
      activeMaddieTimer.value.remainingTime = remaining
      
      console.log(`⏰ Maddie timer: ${remaining}s remaining`)
      
      if (remaining <= 0) {
        console.log('🚫 Maddie timer expired')
        clearMaddieTimer()
      }
    } else {
      clearMaddieTimer()
    }
  }, 1000)
}

function clearMaddieTimer() {
  console.log('🧹 Clearing maddie timer')
  if (maddieTimerInterval) {
    clearInterval(maddieTimerInterval)
    maddieTimerInterval = null
  }
  activeMaddieTimer.value = null
}

function detectMaddieActivation(oldMaddie: any, newMaddie: any) {
  console.log('🔍 detectMaddieActivation called:', { oldMaddie, newMaddie })
  
  // Handle both boolean (legacy) and object (new) maddie structures
  const oldActivated = typeof oldMaddie === 'boolean' ? oldMaddie : oldMaddie?.activated
  const oldCountdown = typeof oldMaddie === 'object' ? oldMaddie?.countdown : false
  
  const newActivated = typeof newMaddie === 'boolean' ? newMaddie : newMaddie?.activated
  const newCountdown = typeof newMaddie === 'object' ? newMaddie?.countdown : false
  
  console.log('🔍 Maddie state comparison:', {
    oldActivated,
    newActivated,
    oldCountdown,
    newCountdown,
    willTriggerCountdown: !oldCountdown && newCountdown,
    willTriggerActivation: !oldActivated && newActivated,
    isLegacyActivation: typeof newMaddie === 'boolean' && !oldMaddie && newMaddie
  })
  
  // Check for countdown start (new system)
  if (!oldCountdown && newCountdown && typeof newMaddie === 'object') {
    console.log('🕐 STARTING Maddie countdown!')
    startMaddieCountdown(newMaddie)
  }
  // Check for direct activation (new system without countdown)
  else if (!oldActivated && newActivated && !newCountdown && typeof newMaddie === 'object') {
    console.log('🚀 TRIGGERING Maddie activation!')
    triggerMaddieActivation(newMaddie)
  }
  // Legacy boolean system support (fallback)
  else if (typeof newMaddie === 'boolean' && !oldMaddie && newMaddie) {
    console.log('🎪 TRIGGERING Legacy Maddie activation!')
    triggerMaddieFlash()
  }
  
  // Check for maddie deactivation (clear timer)
  if (oldActivated && !newActivated) {
    console.log('🚫 Maddie deactivated - clearing timer')
    clearMaddieTimer()
  }
}

function detectBoosterActivation(oldBoosters: any, newBoosters: any) {
  console.log('🔍 detectBoosterActivation called:', { oldBoosters, newBoosters })
  
  if (!oldBoosters || !newBoosters) {
    console.log('❌ Missing booster data for activation detection')
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
        oldCountdown: oldBooster?.countdown,
        newCountdown: newBooster.countdown,
        willTriggerCountdown: oldBooster && !oldBooster.countdown && newBooster.countdown,
        willTriggerActivation: oldBooster && !oldBooster.activated && newBooster.activated,
        boosterName: newBooster.name || newBooster.id
      })
      
      // Check for countdown start
      if (oldBooster && !oldBooster.countdown && newBooster.countdown) {
        console.log('🕐 STARTING Team A booster countdown!')
        startBoosterCountdown('teamA', newBooster, teamA.value?.name || 'Team A', index)
      }
      // Check for direct activation (fallback for existing system)
      else if (oldBooster && !oldBooster.activated && newBooster.activated && !newBooster.countdown) {
        console.log('🚀 TRIGGERING Team A booster activation!')
        triggerBoosterActivation('teamA', newBooster, teamA.value?.name || 'Team A')
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
        oldCountdown: oldBooster?.countdown,
        newCountdown: newBooster.countdown,
        willTriggerCountdown: oldBooster && !oldBooster.countdown && newBooster.countdown,
        willTriggerActivation: oldBooster && !oldBooster.activated && newBooster.activated,
        boosterName: newBooster.name || newBooster.id
      })
      
      // Check for countdown start
      if (oldBooster && !oldBooster.countdown && newBooster.countdown) {
        console.log('🕐 STARTING Team B booster countdown!')
        startBoosterCountdown('teamB', newBooster, teamB.value?.name || 'Team B', index)
      }
      // Check for direct activation (fallback for existing system)
      else if (oldBooster && !oldBooster.activated && newBooster.activated && !newBooster.countdown) {
        console.log('🚀 TRIGGERING Team B booster activation!')
        triggerBoosterActivation('teamB', newBooster, teamB.value?.name || 'Team B')
      }
    })
  }
}

// Clear all active booster timers
function clearAllBoosterTimers() {
  console.log('🧹 Clearing all active booster timers')
  
  // Clear all timer intervals
  Object.values(activeTimerIntervals.value).forEach(intervalId => {
    clearInterval(intervalId)
  })
  
  // Clear the tracking objects
  activeTimerIntervals.value = {}
  activeBoosterTimers.value = {}
}

// Format remaining time for booster timers
const formatBoosterTime = (seconds: number): string => {
  if (seconds <= 0) return '0:00'
  const mins = Math.floor(seconds / 60)
  const secs = seconds % 60
  return `${mins}:${secs.toString().padStart(2, '0')}`
}

// Format remaining time for maddie timer
const formatMaddieTime = (seconds: number): string => {
  if (seconds <= 0) return '0:00'
  const mins = Math.floor(seconds / 60)
  const secs = seconds % 60
  return `${mins}:${secs.toString().padStart(2, '0')}`
}

// Helper function to get active timer for a specific booster
const getBoosterTimer = (teamKey: 'teamA' | 'teamB', boosterId: string) => {
  for (const [key, timer] of Object.entries(activeBoosterTimers.value)) {
    if (timer.team === teamKey && timer.booster.id === boosterId) {
      return timer
    }
  }
  return null
}

// Mark booster as expired in database
async function markBoosterAsExpired(teamKey: string, boosterId: string) {
  if (!currentMatch.value) return
  
  try {
    console.log(`🚫 Marking booster ${boosterId} as expired for ${teamKey}`)
    
    // Get current boosters
    const updatedBoosters = { ...currentMatch.value.boosters }
    
    // Find and mark the booster as expired
    if (updatedBoosters[teamKey]) {
      updatedBoosters[teamKey] = updatedBoosters[teamKey].map((booster: any) => {
        if (booster.id === boosterId) {
          return { ...booster, expired: true }
        }
        return booster
      })
    }
    
    // Update database
    const { error } = await supabase
      .from('matches')
      .update({ boosters: updatedBoosters })
      .eq('id', currentMatch.value.id)
      
    if (error) {
      console.error('Error marking booster as expired:', error)
    } else {
      console.log(`✅ Booster ${boosterId} marked as expired in database`)
    }
  } catch (error) {
    console.error('Error marking booster as expired:', error)
  }
}

// Watch for match changes to debug team loading
watch(
  () => currentMatch.value,
  async (newMatch, oldMatch) => {
    if (newMatch?.id !== oldMatch?.id) {
      console.log('📡 Match changed in scoreboard:', {
        old_match_id: oldMatch?.id,
        new_match_id: newMatch?.id,
        team_a_id: newMatch?.team_a,
        team_b_id: newMatch?.team_b,
        team_a_found: !!(newMatch?.team_a && teams.value[newMatch.team_a]),
        team_b_found: !!(newMatch?.team_b && teams.value[newMatch.team_b]),
        team_a_name: newMatch?.team_a ? teams.value[newMatch.team_a]?.name : undefined,
        team_b_name: newMatch?.team_b ? teams.value[newMatch.team_b]?.name : undefined,
        available_teams: Object.keys(teams.value),
        teams_count: Object.keys(teams.value).length
      })
      
      // Clear all booster timers when match changes to prevent carryover
      clearAllBoosterTimers()
      
      // Clear any active maddie countdowns
      if (maddieCountdownInterval) {
        clearInterval(maddieCountdownInterval)
        maddieCountdownInterval = null
      }
      maddieCountdown.value = null
      
      // If teams are missing, reload them
      if (newMatch?.team_a && !teams.value[newMatch.team_a] || 
          newMatch?.team_b && !teams.value[newMatch.team_b]) {
        console.log('📡 Teams missing for match, reloading teams...')
        await loadTeams()
      }
      
      // Initialize phase tracking for new match
      if (newMatch) {
        initializeMatchPhase()
      }
    }
  },
  { deep: true }
)

// Watch for time_left changes to update current phase
watch(
  () => currentMatch.value?.time_left,
  () => {
    if (currentMatch.value) {
      calculateCurrentPhase()
    }
  }
)

// Watch for booster selection completion and auto-close overlay
watch(
  () => currentMatch.value?.boosters?.selection_phase,
  (newPhase, oldPhase) => {
    if (newPhase === 'complete' && oldPhase !== 'complete') {
      console.log('🎯 Scoreboard detected booster selection complete - starting auto-close timer')
      
      // FALLBACK: If admin auto-confirmation fails, do it from scoreboard side
      setTimeout(() => {
        if (currentMatch.value?.boosters?.selection_active === true) {
          console.log('🎯 Admin auto-confirmation failed - doing fallback confirmation from scoreboard')
          
          // Check if we have current_boosters data to transfer
          const currentBoosters = currentMatch.value?.boosters?.current_boosters
          if (currentBoosters?.teamA?.length > 0 && currentBoosters?.teamB?.length > 0) {
            console.log('🎯 Transferring boosters from current_boosters to final location')
            
            // Update the match directly to transfer the boosters
            if (currentMatch.value?.boosters) {
              currentMatch.value.boosters.teamA = currentBoosters.teamA.map((booster: any) => ({
                ...booster,
                available: true,
                activated: false,
                used: false
              }))
              currentMatch.value.boosters.teamB = currentBoosters.teamB.map((booster: any) => ({
                ...booster,
                available: true,
                activated: false,
                used: false
              }))
              currentMatch.value.boosters.selection_active = false
              currentMatch.value.boosters.selection_phase = null
              currentMatch.value.boosters.current_boosters = null
              
              console.log('✅ Fallback confirmation completed - boosters should now be visible!')
            }
          } else {
            console.log('🎯 Auto-closing booster overlay after timeout (no data to transfer)')
            forceCloseBoosterOverlay()
          }
        }
      }, 2000) // 2 second timeout - shorter since we're doing the work ourselves
    }
  }
)

// Sound helper functions
async function playMaddieSound() {
  try {
    // Try to play custom sound if set
    await SoundManager.playSound('/sounds/maddies/default.mp3')
  } catch (error) {
    console.log('Playing default maddie sound')
    try {
      await SoundManager.playSound('/sounds/maddie.mp3')
    } catch (fallbackError) {
      console.warn('No maddie sound available')
    }
  }
}

async function playBoosterSound(booster?: any) {
  try {
    // If booster has a custom sound file, try to play it
    if (booster?.sound_file) {
      if (booster.sound_file.startsWith('custom_')) {
        // Custom uploaded file - get from localStorage
        const customSoundData = SoundManager.getCustomSound(booster.sound_file)
        if (customSoundData) {
          await SoundManager.playSound(customSoundData)
          return
        }
      } else {
        // Default file from boosters folder
        await SoundManager.playSound(`/sounds/boosters/${booster.sound_file}`)
        return
      }
    }

    // Fallback to default booster sound
    await SoundManager.playSound('/sounds/booster-activate.mp3')
  } catch (error) {
    console.log('Playing fallback booster sound')
    try {
      await SoundManager.playSound('/sounds/whistle.mp3')
    } catch (fallbackError) {
      console.warn('No booster sound available')
    }
  }
}

async function playSpinningSound() {
  try {
    // Play a spinning/slot machine sound effect
    await SoundManager.playSound('/sounds/booster_spin.wav', 0.6)
    console.log('🔊 Playing spinning sound on scoreboard')
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
    await SoundManager.playSound('/sounds/selection.mp3', 0.7)
    console.log('🔊 Playing booster selection sound on scoreboard')
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

// Watch for spinning state changes to play sounds
let previousSpinningState = false
let previousSpinningSlot = -1

watch(() => currentMatch.value?.boosters?.is_spinning, (isSpinning) => {
  if (isSpinning && !previousSpinningState) {
    // Spinning just started
    playSpinningSound()
  } else if (!isSpinning && previousSpinningState) {
    // Spinning just stopped - booster was selected
    playBoosterSelectionSound()
  }
  previousSpinningState = !!isSpinning
}, { immediate: true })

// Also watch for slot changes during spinning (optional: could add tick sounds)
watch(() => currentMatch.value?.boosters?.spinning_slot, (newSlot) => {
  if (currentMatch.value?.boosters?.is_spinning && newSlot !== previousSpinningSlot) {
    // Optional: play a subtle tick sound for each slot change
    // Uncomment if you want tick sounds during spinning:
    // playTickSound()
  }
  previousSpinningSlot = newSlot || -1
}, { immediate: true })

// Watch for match changes to set up subscription
watch(() => currentMatch.value?.id, (newId, oldId) => {
  if (newId && newId !== oldId) {
    console.log('🔧 Match changed, setting up new subscription for:', newId)
    console.log('🔧 Match details:', { 
      id: newId, 
      teamA: currentMatch.value?.team_a, 
      teamB: currentMatch.value?.team_b,
      status: currentMatch.value?.status
    })
    
    // Unsubscribe from old subscription
    if (realtimeSubscription) {
      realtimeSubscription.unsubscribe()
    }
    
    // Set up new subscription
    setupRealtimeSubscription()
  }
}, { immediate: true })

onMounted(async () => {
  loading.value = true
  await Promise.all([loadCurrentMatch(), loadTeams(), loadBoostersAndMaddies()])
  // setupRealtimeSubscription() is now handled by the watch
  loading.value = false
})

onUnmounted(() => {
  if (realtimeSubscription) {
    realtimeSubscription.unsubscribe()
  }
  stopLocalTimer()
  
  // Clear countdown timer if active
  if (countdownInterval) {
    clearInterval(countdownInterval)
    countdownInterval = null
  }
  
  // Clear maddie countdown timer if active
  if (maddieCountdownInterval) {
    clearInterval(maddieCountdownInterval)
    maddieCountdownInterval = null
  }
  
  // Clear all booster timers
  clearAllBoosterTimers()
})
</script>

<template>
  <div 
    class="min-h-screen transition-colors duration-500"
    :class="{ 'animate-flash': maddieFlash }"
    :style="{ 
      backgroundColor: themeStore.currentTheme?.colors.background,
      color: themeStore.currentTheme?.colors.text
    }"
  >
    <div v-if="loading" class="flex items-center justify-center h-screen">
      <div class="text-4xl font-bold animate-pulse">{{ $t('scoreboard.loading') }}</div>
    </div>

    <div v-else-if="!currentMatch" class="flex items-center justify-center h-screen text-center">
      <div>
        <div class="mb-8">
          <div v-if="themeStore.currentTheme?.logo" class="logo-bg-light w-32 h-32 mx-auto mb-4 flex items-center justify-center">
            <img 
              :src="themeStore.currentTheme.logo" 
              :alt="themeStore.currentTheme.name"
              class="w-24 h-24 animate-pulse"
            />
          </div>
          <div v-else class="text-6xl mb-4">🏒</div>
        </div>
        <h2 class="hc-title mb-4">
          {{ $t('scoreboard.noActiveMatch') }}
        </h2>
        <p class="hc-body">
          {{ $t('scoreboard.checkBackMessage') }}
        </p>
      </div>
    </div>

    <!-- Booster Selection Overlay -->
    <div 
      v-if="shouldShowBoosterOverlay"
      class="fixed inset-0 bg-gradient-to-r from-[#121238] to-[#478dcb] flex items-center justify-center z-50"
    >
      <div class="text-center">
        <h1 class="text-6xl font-bold mb-8 text-white">
          {{ $t('scoreboard.boosterSelection') }}
        </h1>
        
        <div class="text-3xl font-bold text-white mb-8">
          {{ getBoosterSelectionPhaseText() }}
        </div>
        
        <!-- Slot Machine Animation (only show when spinning) -->
        <div v-if="currentMatch?.boosters?.is_spinning" class="mb-8">
          <div class="text-2xl font-bold text-yellow-300 mb-4">
            {{ $t('scoreboard.spinningFor', { team: currentMatch.boosters.current_team === 'A' ? teamA?.name : teamB?.name }) }}
          </div>
          
          <!-- Slot Machine Display -->
          <div class="mx-auto bg-gradient-to-b from-yellow-600 to-yellow-800 rounded-2xl p-8 max-w-lg shadow-2xl border-4 border-yellow-500 animate-pulse">
            <div class="bg-black rounded-xl p-6 mb-4 border-2 border-yellow-400">
              <div class="text-center">
                <div class="text-8xl mb-4 animate-bounce" style="animation-duration: 0.3s;">
                  {{ availableBoosters[currentMatch.boosters.spinning_slot || 0]?.icon || '🎲' }}
                </div>
                <div class="text-2xl font-bold text-yellow-300 animate-pulse">
                  {{ availableBoosters[currentMatch.boosters.spinning_slot || 0]?.name || 'Spinning...' }}
                </div>
                <div class="text-sm text-yellow-200 mt-2">
                  {{ availableBoosters[currentMatch.boosters.spinning_slot || 0]?.description || 'Rolling the dice...' }}
                </div>
              </div>
            </div>
            <div class="text-center text-yellow-100 font-bold text-xl animate-pulse">
              {{ $t('scoreboard.hockeyCasino') }}
            </div>
            <div class="text-center text-yellow-300 text-sm mt-2">
              {{ $t('scoreboard.boosterSelectionLabel') }}
            </div>
          </div>
        </div>
        
        <!-- Team Boosters Display -->
        <div class="grid grid-cols-2 gap-12 max-w-4xl">
          <!-- Team A Boosters -->
          <div class="bg-white/10 rounded-xl p-6 border-2 border-blue-500/50">
            <h3 class="text-2xl font-bold text-blue-300 mb-4">{{ teamA?.name || 'Team A' }}</h3>
            <div v-if="currentMatch?.boosters?.current_boosters?.teamA && currentMatch.boosters.current_boosters.teamA.length > 0" class="space-y-2">
              <div 
                v-for="(booster, index) in currentMatch.boosters.current_boosters.teamA" 
                :key="index"
                class="bg-blue-500/20 rounded-lg p-3"
              >
                <div class="text-lg font-bold">{{ booster.icon }} {{ booster.name }}</div>
                <div class="text-sm text-blue-200">{{ booster.description }}</div>
              </div>
            </div>
            <div v-else class="text-blue-300 italic">{{ $t('scoreboard.waitingForBoosters') }}</div>
          </div>
          
          <!-- Team B Boosters -->
          <div class="bg-white/10 rounded-xl p-6 border-2 border-red-500/50">
            <h3 class="text-2xl font-bold text-red-300 mb-4">{{ teamB?.name || 'Team B' }}</h3>
            <div v-if="currentMatch?.boosters?.current_boosters?.teamB && currentMatch.boosters.current_boosters.teamB.length > 0" class="space-y-2">
              <div 
                v-for="(booster, index) in currentMatch.boosters.current_boosters.teamB" 
                :key="index"
                class="bg-red-500/20 rounded-lg p-3"
              >
                <div class="text-lg font-bold">{{ booster.icon }} {{ booster.name }}</div>
                <div class="text-sm text-red-200">{{ booster.description }}</div>
              </div>
            </div>
            <div v-else class="text-red-300 italic">{{ $t('scoreboard.waitingForBoosters') }}</div>
          </div>
        </div>
        
        <!-- Auto-closing message when selection is complete -->
        <div v-if="currentMatch?.boosters?.selection_phase === 'complete'" class="mt-8">
          <div class="text-green-400 font-bold text-lg">
            {{ $t('scoreboard.boostersConfirmed') }}
          </div>
          <div class="text-sm text-white/70 mt-2">
            {{ $t('scoreboard.returningToScoreboard') }}
          </div>
        </div>
      </div>
    </div>

    <div v-else class="container mx-auto px-4 py-8 h-screen flex flex-col">
      <!-- Header -->
      <div class="header-section text-center mb-8">
        <div class="flex items-center justify-center mb-4">
          <!-- Theme Logo with proper background for dark logos -->
          <div v-if="themeStore.currentTheme?.logo" class="logo-bg-light mr-4">
            <img 
              :src="themeStore.currentTheme.logo" 
              :alt="themeStore.currentTheme.name"
              class="w-16 h-16"
            />
          </div>
          <div v-else class="text-4xl mr-4">🏒</div>
          
          <!-- Title with clean HC Lokeren styling -->
          <h1 class="hc-title">
            {{ themeStore.currentTheme?.name || $t('home.title') }}
          </h1>
        </div>
        
        <!-- Live indicator -->
        <div class="flex items-center justify-center space-x-2 mb-4">
          <div class="w-3 h-3 bg-red-500 rounded-full animate-pulse"></div>
          <span class="text-lg font-medium font-theme-text"
                :style="{ color: themeStore.currentTheme?.colors.textSecondary }">
            {{ $t('scoreboard.liveUpdate') || 'LIVE' }}
          </span>
        </div>
        
        <!-- Debug: Show raw booster data -->
        <!-- <div v-if="currentMatch?.boosters" class="text-xs text-white bg-black/50 p-2 rounded mb-4 max-w-2xl mx-auto">
          <div class="font-bold mb-1">🐛 DEBUG - Booster Data:</div>
          <div>TeamA: {{ JSON.stringify(currentMatch.boosters.teamA) }}</div>
          <div>TeamB: {{ JSON.stringify(currentMatch.boosters.teamB) }}</div>
          <div>Current TeamA: {{ JSON.stringify(currentMatch.boosters.current_boosters?.teamA) }}</div>
          <div>Current TeamB: {{ JSON.stringify(currentMatch.boosters.current_boosters?.teamB) }}</div>
          <div>Selection Active: {{ currentMatch.boosters.selection_active }}</div>
          <div>Selection Phase: {{ currentMatch.boosters.selection_phase }}</div>
        </div>-->
        <div class="flex items-center justify-center space-x-6">
          <div 
            class="px-4 py-2 rounded-full text-white font-bold animate-pulse-fast"
            :class="currentMatch ? getStatusColor(currentMatch.status) : 'bg-gray-500'"
          >
            {{ currentMatch ? getStatusText(currentMatch.status) : 'LOADING' }}
          </div>
          <div class="text-center">
            <div class="text-lg font-semibold text-blue-200 mb-1">
              {{ currentPhaseLabel }}
            </div>
            <div class="text-2xl font-mono">
              {{ formatTime(phaseTimeLeft) }}
            </div>
          </div>
        </div>
      </div>

      <!-- Active Boosters Banner -->
      <div v-if="currentMatch?.boosters && (currentMatch.boosters.teamA?.some((b: any) => b.activated && !b.expired) || currentMatch.boosters.teamB?.some((b: any) => b.activated && !b.expired))" 
           class="mb-8">
        <div class="max-w-6xl mx-auto">
          <!-- Banner Header -->
          <div class="text-center mb-4">
            <h3 class="text-2xl font-bold text-yellow-400 animate-pulse">⚡ ACTIVE BOOSTERS ⚡</h3>
          </div>
          
          <!-- Active Boosters Grid -->
          <div class="space-y-4">
            <!-- Team A Active Boosters -->
            <div v-if="currentMatch.boosters.teamA?.some((b: any) => b.activated && !b.expired)" 
                 class="w-full bg-gradient-to-r from-[#121238]/80 to-[#478dcb]/80 backdrop-blur-sm rounded-xl p-4 border-2 border-[#478dcb]">
              <div class="text-center mb-3">
                <h4 class="text-lg font-bold text-white">{{ teamA?.name || 'Team A' }}</h4>
              </div>
              <div class="space-y-2">
                <template v-for="booster in currentMatch.boosters.teamA" :key="`banner-a-${booster.id}`">
                  <div v-if="booster.activated && !booster.expired" 
                       class="bg-green-500/90 rounded-lg p-3 border border-green-300 animate-pulse relative overflow-hidden">
                    <!-- Sparkle overlay -->
                    <div class="absolute inset-0 bg-gradient-to-r from-green-400/30 to-emerald-400/30 animate-pulse rounded-lg"></div>
                    
                    <div class="relative z-10 flex items-center justify-between text-white">
                      <div class="flex items-center space-x-3">
                        <span class="text-3xl animate-bounce">{{ booster.icon }}</span>
                        <div>
                          <div class="font-bold text-lg">{{ booster.name }}</div>
                          <div class="text-sm opacity-90">{{ booster.description || 'Active boost effect' }}</div>
                        </div>
                      </div>
                      
                      <!-- Timer or Status -->
                      <div class="text-right">
                        <div v-if="booster.duration && getBoosterTimer('teamA', booster.id)" 
                             class="bg-yellow-500 text-black px-3 py-1 rounded-full text-sm font-bold font-mono animate-pulse">
                          ⏰ {{ formatBoosterTime(getBoosterTimer('teamA', booster.id)?.remainingTime || 0) }}
                        </div>
                        <div v-else-if="!booster.duration" 
                             class="bg-orange-500 text-white px-3 py-1 rounded-full text-sm font-bold animate-bounce">
                          ⚡ INSTANT
                        </div>
                      </div>
                    </div>
                    
                    <!-- Visual effects -->
                    <div class="absolute top-1 right-1 text-yellow-300 animate-spin">✨</div>
                  </div>
                </template>
              </div>
            </div>
            
            <!-- Team B Active Boosters -->
            <div v-if="currentMatch.boosters.teamB?.some((b: any) => b.activated && !b.expired)" 
                 class="w-full bg-gradient-to-r from-[#478dcb]/80 to-[#121238]/80 backdrop-blur-sm rounded-xl p-4 border-2 border-[#121238]">
              <div class="text-center mb-3">
                <h4 class="text-lg font-bold text-white">{{ teamB?.name || 'Team B' }}</h4>
              </div>
              <div class="space-y-2">
                <template v-for="booster in currentMatch.boosters.teamB" :key="`banner-b-${booster.id}`">
                  <div v-if="booster.activated && !booster.expired" 
                       class="bg-green-500/90 rounded-lg p-3 border border-green-300 animate-pulse relative overflow-hidden">
                    <!-- Sparkle overlay -->
                    <div class="absolute inset-0 bg-gradient-to-r from-green-400/30 to-emerald-400/30 animate-pulse rounded-lg"></div>
                    
                    <div class="relative z-10 flex items-center justify-between text-white">
                      <div class="flex items-center space-x-3">
                        <span class="text-3xl animate-bounce">{{ booster.icon }}</span>
                        <div>
                          <div class="font-bold text-lg">{{ booster.name }}</div>
                          <div class="text-sm opacity-90">{{ booster.description || 'Active boost effect' }}</div>
                        </div>
                      </div>
                      
                      <!-- Timer or Status -->
                      <div class="text-right">
                        <div v-if="booster.duration && getBoosterTimer('teamB', booster.id)" 
                             class="bg-yellow-500 text-black px-3 py-1 rounded-full text-sm font-bold font-mono animate-pulse">
                          ⏰ {{ formatBoosterTime(getBoosterTimer('teamB', booster.id)?.remainingTime || 0) }}
                        </div>
                        <div v-else-if="!booster.duration" 
                             class="bg-orange-500 text-white px-3 py-1 rounded-full text-sm font-bold animate-bounce">
                          ⚡ INSTANT
                        </div>
                      </div>
                    </div>
                    
                    <!-- Visual effects -->
                    <div class="absolute top-1 right-1 text-yellow-300 animate-spin">✨</div>
                  </div>
                </template>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Maddie Information Display (Above Main Scoreboard) -->
      <div 
        v-if="currentMatch?.maddie && ((typeof currentMatch.maddie === 'object' && currentMatch.maddie.activated) || (typeof currentMatch.maddie === 'boolean' && currentMatch.maddie))"
        class="flex justify-center mb-6"
      >
        <div class="bg-purple-600/90 backdrop-blur-sm rounded-xl border-2 border-purple-400 p-6 shadow-lg w-full max-w-6xl mx-4">
          <div class="flex items-center justify-center mb-3">
            <span class="text-4xl mr-3 animate-pulse">
              {{ (currentMatch && typeof currentMatch.maddie === 'object') ? currentMatch.maddie.icon || '🎪' : '🎪' }}
            </span>
            <div class="text-lg font-bold text-purple-200 uppercase tracking-wide">Maddie Effect Active</div>
          </div>
          <div class="text-2xl font-bold text-white mb-2 text-center">
            {{ (currentMatch && typeof currentMatch.maddie === 'object') ? (currentMatch.maddie.name || currentMatch.maddie.title || 'Special Effect') : 'Special Effect' }}
          </div>
          <div 
            v-if="currentMatch && typeof currentMatch.maddie === 'object' && (currentMatch.maddie.description || currentMatch.maddie.subtitle)"
            class="text-lg text-purple-100 leading-relaxed text-center mb-2"
          >
            {{ currentMatch.maddie.description || currentMatch.maddie.subtitle }}
          </div>
          <div 
            v-if="activeMaddieTimer"
            class="text-lg text-purple-200 font-semibold text-center bg-purple-800/50 rounded-lg px-4 py-2 border border-purple-400"
          >
            <div class="flex items-center justify-center space-x-2">
              <span class="text-yellow-400 animate-pulse">⏰</span>
              <span class="font-mono text-xl">{{ formatMaddieTime(activeMaddieTimer.remainingTime) }}</span>
              <span class="text-sm">remaining</span>
            </div>
          </div>
          <div 
            v-else-if="currentMatch && typeof currentMatch.maddie === 'object' && currentMatch.maddie.duration"
            class="text-md text-purple-200 font-semibold text-center"
          >
            ⏱️ Duration: {{ currentMatch.maddie.duration }}s
          </div>
        </div>
      </div>

      <!-- Maddie Flash Overlay (Above Main Scoreboard) -->
      <div 
        v-if="maddieFlash"
        class="flex justify-center mb-4"
      >
        <div class="bg-yellow-400/80 backdrop-blur-sm rounded-2xl border-4 border-yellow-300 p-6 shadow-2xl animate-pulse">
          <div class="flex items-center justify-center space-x-4">
            <div class="text-6xl animate-bounce">🎪</div>
            <div class="text-3xl font-bold text-yellow-900">SPECIAL EFFECT ACTIVATED!</div>
            <div class="text-6xl animate-bounce">🎪</div>
          </div>
        </div>
      </div>

      <!-- Main Scoreboard -->
      <div class="flex-1 flex items-center justify-center">
        <div class="grid grid-cols-3 gap-8 w-full max-w-6xl">
          <!-- Team A -->
          <div class="text-center">
            <div class="scoreboard-card">
              <h2 class="team-name hc-subtitle">
                {{ teamA?.name || 'Team A' }}
              </h2>
              <div class="score-display">
                {{ currentMatch?.score_a || 0 }}
              </div>
              
              <!-- Team A Boosters (Under Score) -->
              <div v-if="currentMatch?.boosters?.teamA?.length > 0" class="mb-4">
                <div class="space-y-2">
                  <div 
                    v-for="booster in currentMatch?.boosters?.teamA || []" 
                    :key="booster.id"
                    class="text-xs px-3 py-2 rounded-lg shadow-md border mx-auto max-w-xs relative overflow-hidden transition-all duration-300"
                    :class="[
                      booster.expired ? 'bg-gradient-to-r from-gray-600 to-gray-700 border-gray-500 text-gray-300 opacity-75' :
                      booster.activated ? 
                      'bg-gradient-to-r from-green-600 to-emerald-600 border-green-400 text-white' : 
                      'bg-gradient-to-r from-[#121238] to-[#478dcb] border-[#478dcb] text-white'
                    ]"
                  >
                    <!-- Animated background for activated boosters -->
                    <div 
                      v-if="booster.activated && !booster.expired"
                      class="absolute inset-0 bg-gradient-to-r from-green-400/30 to-emerald-400/30 animate-pulse"
                    ></div>
                    
                    <!-- Strikethrough overlay for expired boosters -->
                    <div 
                      v-if="booster.expired"
                      class="absolute inset-0 flex items-center justify-center z-20"
                    >
                      <div class="w-full h-0.5 bg-red-500 transform rotate-12"></div>
                      <div class="w-full h-0.5 bg-red-500 transform -rotate-12 absolute"></div>
                    </div>
                    
                    <div class="font-bold text-center flex items-center justify-center space-x-1 relative z-10" :class="booster.expired ? 'line-through' : ''">
                      <span>{{ booster.icon }}</span>
                      <span>{{ booster.name }}</span>
                      <span v-if="booster.activated && booster.duration && !booster.expired" class="text-yellow-300 animate-bounce">⏰</span>
                      <span v-if="booster.expired" class="text-red-400">🚫</span>
                    </div>
                    
                    <!-- Show countdown for timed activated boosters -->
                    <div 
                      v-if="booster.activated && booster.duration && getBoosterTimer('teamA', booster.id)"
                      class="text-center mt-1 relative z-10"
                    >
                      <div class="text-yellow-300 font-mono text-xs animate-pulse">
                        {{ formatBoosterTime(getBoosterTimer('teamA', booster.id)?.remainingTime || 0) }} remaining
                      </div>
                    </div>
                    
                    <!-- Status indicator -->
                    <div class="text-center mt-1 relative z-10">
                      <span 
                        v-if="booster.expired"
                        class="status-expired text-xs px-2 py-1 rounded-full font-semibold"
                      >
                        🚫 EXPIRED
                      </span>
                      <span 
                        v-else-if="booster.activated"
                        class="status-active text-xs px-2 py-1 rounded-full font-semibold animate-pulse"
                      >
                        🟢 ACTIVE
                      </span>
                      <span 
                        v-else
                        class="status-ready text-xs px-2 py-1 rounded-full font-semibold"
                      >
                        💤 READY
                      </span>
                    </div>
                  </div>
                </div>
              </div>
              
              <div class="space-y-3">
                <!-- Total Cards -->
                <div v-if="currentMatch?.cards?.team_a" class="flex justify-center space-x-2">
                  <div 
                    v-for="[cardType, count] in Object.entries(currentMatch.cards.team_a)" 
                    :key="cardType"
                    class="flex items-center space-x-1"
                  >
                    <div 
                      class="w-4 h-6 rounded-sm"
                      :class="{
                        'bg-yellow-400': cardType === 'yellow',
                        'bg-green-500': cardType === 'green',
                        'bg-red-500': cardType === 'red'
                      }"
                    ></div>
                    <span class="text-sm">{{ count }}</span>
                  </div>
                </div>
                
                <!-- Active Player Penalties -->
                <div v-if="getActivePenalties('team_a').length > 0" class="space-y-1">
                  <div class="text-xs font-semibold text-blue-300">PENALTIES:</div>
                  <div 
                    v-for="penalty in getActivePenalties('team_a')" 
                    :key="penalty.playerId"
                    class="text-xs px-2 py-1 rounded"
                    :class="{
                      'bg-yellow-500 text-black': penalty.type === 'yellow',
                      'bg-green-600 text-white': penalty.type === 'green',
                      'bg-red-600 text-white': penalty.type === 'red'
                    }"
                  >
                    #{{ penalty.playerNumber }} {{ penalty.playerName }} - {{ penalty.timeRemaining }}
                  </div>
                </div>


              </div>
            </div>
          </div>

          <!-- VS / Timer -->
          <div class="text-center flex flex-col justify-center">
            <!-- Timer and Phase -->
            <div class="vs-section mb-4">
              <div class="hc-subtitle text-white mb-2">
                {{ currentPhaseLabel }}
              </div>
              <div class="text-4xl font-mono text-white">
                {{ formatTime(phaseTimeLeft) }}
              </div>
            </div>



            <!-- VS Section -->
            <div class="vs-section mb-4">
              <div class="text-6xl font-bold mb-2 hc-link">
                VS
              </div>
            </div>

            <!-- Match Status -->
            <div 
              class="px-6 py-3 rounded-full text-white font-bold text-xl font-theme-links"
              :class="currentMatch ? getStatusColor(currentMatch.status) : 'bg-gray-500'"
            >
              {{ currentMatch ? getStatusText(currentMatch.status) : 'LOADING' }}
            </div>
          </div>

          <!-- Team B -->
          <div class="text-center">
            <div class="scoreboard-card">
              <h2 class="team-name secondary-team hc-subtitle">
                {{ teamB?.name || 'Team B' }}
              </h2>
              <div class="score-display">
                {{ currentMatch?.score_b || 0 }}
              </div>
              
              <!-- Team B Boosters (Under Score) -->
              <div v-if="currentMatch?.boosters?.teamB?.length > 0" class="mb-4">
                <div class="space-y-2">
                  <div 
                    v-for="booster in currentMatch?.boosters?.teamB || []" 
                    :key="booster.id"
                    class="text-xs px-3 py-2 rounded-lg shadow-md border mx-auto max-w-xs relative overflow-hidden transition-all duration-300"
                    :class="[
                      booster.expired ? 'bg-gradient-to-r from-gray-600 to-gray-700 border-gray-500 text-gray-300 opacity-75' :
                      booster.activated ? 
                      'bg-gradient-to-r from-green-600 to-emerald-600 border-green-400 text-white' : 
                      'bg-gradient-to-r from-red-600 to-rose-600 border-red-300 text-red-100'
                    ]"
                  >
                    <!-- Animated background for activated boosters -->
                    <div 
                      v-if="booster.activated && !booster.expired"
                      class="absolute inset-0 bg-gradient-to-r from-green-400/30 to-emerald-400/30 animate-pulse"
                    ></div>
                    
                    <!-- Strikethrough overlay for expired boosters -->
                    <div 
                      v-if="booster.expired"
                      class="absolute inset-0 flex items-center justify-center z-20"
                    >
                      <div class="w-full h-0.5 bg-red-500 transform rotate-12"></div>
                      <div class="w-full h-0.5 bg-red-500 transform -rotate-12 absolute"></div>
                    </div>
                    
                    <div class="font-bold text-center flex items-center justify-center space-x-1 relative z-10" :class="booster.expired ? 'line-through' : ''">
                      <span>{{ booster.icon }}</span>
                      <span>{{ booster.name }}</span>
                      <span v-if="booster.activated && booster.duration && !booster.expired" class="text-yellow-300 animate-bounce">⏰</span>
                      <span v-if="booster.expired" class="text-red-400">🚫</span>
                    </div>
                    
                    <!-- Show countdown for timed activated boosters -->
                    <div 
                      v-if="booster.activated && booster.duration && getBoosterTimer('teamB', booster.id)"
                      class="text-center mt-1 relative z-10"
                    >
                      <div class="text-yellow-300 font-mono text-xs animate-pulse">
                        {{ formatBoosterTime(getBoosterTimer('teamB', booster.id)?.remainingTime || 0) }} remaining
                      </div>
                    </div>
                    
                    <!-- Status indicator -->
                    <div class="text-center mt-1 relative z-10">
                      <span 
                        v-if="booster.expired"
                        class="status-expired text-xs px-2 py-1 rounded-full font-semibold"
                      >
                        🚫 EXPIRED
                      </span>
                      <span 
                        v-else-if="booster.activated"
                        class="status-active text-xs px-2 py-1 rounded-full font-semibold animate-pulse"
                      >
                        🟢 ACTIVE
                      </span>
                      <span 
                        v-else
                        class="status-ready text-xs px-2 py-1 rounded-full font-semibold"
                      >
                        💤 READY
                      </span>
                    </div>
                  </div>
                </div>
              </div>
              
              <div class="space-y-3">
                <!-- Total Cards -->
                <div v-if="currentMatch?.cards?.team_b" class="flex justify-center space-x-2">
                  <div 
                    v-for="[cardType, count] in Object.entries(currentMatch.cards.team_b)" 
                    :key="cardType"
                    class="flex items-center space-x-1"
                  >
                    <div 
                      class="w-4 h-6 rounded-sm"
                      :class="{
                        'bg-yellow-400': cardType === 'yellow',
                        'bg-green-500': cardType === 'green',
                        'bg-red-500': cardType === 'red'
                      }"
                    ></div>
                    <span class="text-sm">{{ count }}</span>
                  </div>
                </div>
                
                <!-- Active Player Penalties -->
                <div v-if="getActivePenalties('team_b').length > 0" class="space-y-1">
                  <div class="text-xs font-semibold text-red-300">PENALTIES:</div>
                  <div 
                    v-for="penalty in getActivePenalties('team_b')" 
                    :key="penalty.playerId"
                    class="text-xs px-2 py-1 rounded"
                    :class="{
                      'bg-yellow-500 text-black': penalty.type === 'yellow',
                      'bg-green-600 text-white': penalty.type === 'green',
                      'bg-red-600 text-white': penalty.type === 'red'
                    }"
                  >
                    #{{ penalty.playerNumber }} {{ penalty.playerName }} - {{ penalty.timeRemaining }}
                  </div>
                </div>


              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Maddie Effect Display -->
      <div v-if="currentMatch?.maddie" class="text-center mb-8">
        <div class="text-4xl font-bold text-yellow-400 animate-bounce">
          🎪 MADDIE EFFECT! 🎪
        </div>
      </div>

      <!-- Footer -->
      <div class="text-center mt-8">
        <div class="flex items-center justify-center space-x-2">
          <img 
            v-if="themeStore.currentTheme?.logo" 
            :src="themeStore.currentTheme.logo" 
            :alt="themeStore.currentTheme.name"
            class="w-6 h-6"
          />
          <span v-else class="text-xl">🏒</span>
          <p class="font-theme-text"
             :style="{ color: themeStore.currentTheme?.colors.textSecondary }">
            Live Tournament Coverage
          </p>
        </div>
      </div>
    </div>

    <!-- Booster Countdown Overlay -->
    <div 
      v-if="boosterCountdown?.active"
      class="fixed inset-0 flex items-center justify-center pointer-events-none z-50"
    >
      <div class="text-center transform animate-pulse">
        <div class="text-9xl mb-4">{{ boosterCountdown.boosterIcon }}</div>
        <div 
          class="text-5xl font-bold mb-4"
          :class="{
            'text-blue-400': boosterCountdown.teamColor === 'blue',
            'text-red-400': boosterCountdown.teamColor === 'red'
          }"
        >
          {{ boosterCountdown.teamName }}
        </div>
        <div class="text-4xl font-bold text-white mb-4">BOOSTER INCOMING!</div>
        <div 
          class="text-3xl font-bold px-8 py-4 rounded-2xl border-4 mb-4"
          :class="{
            'bg-blue-600/80 border-blue-300 text-blue-100': boosterCountdown.teamColor === 'blue',
            'bg-red-600/80 border-red-300 text-red-100': boosterCountdown.teamColor === 'red'
          }"
        >
          {{ boosterCountdown.boosterName }}
        </div>
        <div class="text-8xl font-bold text-yellow-400 animate-bounce">
          {{ boosterCountdown.countdown }}
        </div>
        <div class="text-2xl text-white mt-2">seconds until activation</div>
      </div>
    </div>

    <!-- Maddie Countdown Overlay (Bottom Banner) -->
    <div 
      v-if="maddieCountdown?.active"
      class="fixed bottom-8 left-1/2 transform -translate-x-1/2 pointer-events-none z-50"
    >
      <div class="text-center bg-purple-600/95 backdrop-blur-lg rounded-2xl border-4 border-purple-300 p-6 shadow-2xl max-w-lg mx-auto animate-pulse">
        <div class="flex items-center justify-center mb-3">
          <div class="text-4xl mr-3">{{ maddieCountdown.maddieIcon }}</div>
          <div class="text-2xl font-bold text-purple-100">MADDIE INCOMING!</div>
        </div>
        <div class="text-xl font-bold text-white mb-2">
          {{ maddieCountdown.maddieName }}
        </div>
        <div 
          v-if="maddieCountdown.maddieDescription"
          class="text-sm text-purple-200 leading-relaxed mb-3"
        >
          {{ maddieCountdown.maddieDescription }}
        </div>
        <div class="flex items-center justify-center space-x-3">
          <div class="text-4xl font-bold text-yellow-400 animate-bounce">
            {{ maddieCountdown.countdown }}
          </div>
          <div class="text-lg text-white">seconds</div>
        </div>
      </div>
    </div>

    <!-- Booster Activation Overlay -->
    <div 
      v-if="boosterActivation?.active"
      class="fixed inset-0 flex items-center justify-center pointer-events-none z-40"
    >
      <div class="text-center transform animate-bounce">
        <div class="text-9xl mb-4 animate-pulse">{{ boosterActivation.boosterIcon }}</div>
        <div 
          class="text-5xl font-bold mb-4"
          :class="{
            'text-blue-400': boosterActivation.teamColor === 'blue',
            'text-red-400': boosterActivation.teamColor === 'red'
          }"
        >
          {{ boosterActivation.teamName }}
        </div>
        <div class="text-4xl font-bold text-white mb-2">BOOSTER ACTIVATED!</div>
        <div 
          class="text-3xl font-bold px-8 py-4 rounded-2xl border-4 animate-pulse"
          :class="{
            'bg-blue-600/80 border-blue-300 text-blue-100': boosterActivation.teamColor === 'blue',
            'bg-red-600/80 border-red-300 text-red-100': boosterActivation.teamColor === 'red'
          }"
        >
          {{ boosterActivation.boosterName }}
        </div>
      </div>
    </div>

    <!-- Maddie Activation Overlay (Bottom Banner) -->
    <div 
      v-if="maddieActivation?.active"
      class="fixed bottom-8 left-1/2 transform -translate-x-1/2 pointer-events-none z-40"
    >
      <div class="text-center bg-purple-600/95 backdrop-blur-lg rounded-2xl border-4 border-purple-300 p-6 shadow-2xl max-w-lg mx-auto animate-bounce">
        <div class="flex items-center justify-center mb-3">
          <div class="text-4xl mr-3 animate-pulse">{{ maddieActivation.maddieIcon }}</div>
          <div class="text-2xl font-bold text-purple-100">MADDIE ACTIVATED!</div>
        </div>
        <div class="text-xl font-bold text-white mb-2">
          {{ maddieActivation.maddieName }}
        </div>
        <div 
          v-if="maddieActivation.maddieDescription"
          class="text-sm text-purple-200 leading-relaxed"
        >
          {{ maddieActivation.maddieDescription }}
        </div>
      </div>
    </div>

    <!-- Active Booster Timers Overlay -->
    <div 
      v-if="Object.keys(activeBoosterTimers).length > 0"
      class="fixed top-4 right-4 z-30 space-y-2"
    >
      <div 
        v-for="(timer, key) in activeBoosterTimers" 
        :key="key"
        class="bg-black/80 backdrop-blur-sm rounded-lg p-3 border-2 min-w-48"
        :class="{
          'border-blue-400': timer.team === 'teamA',
          'border-red-400': timer.team === 'teamB'
        }"
      >
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-2">
            <span class="text-2xl">{{ timer.booster.icon }}</span>
            <div>
              <div 
                class="font-bold text-sm"
                :class="{
                  'text-blue-300': timer.team === 'teamA',
                  'text-red-300': timer.team === 'teamB'
                }"
              >
                {{ timer.booster.name }}
              </div>
              <div class="text-xs text-gray-300">{{ timer.team === 'teamA' ? (teamA?.name || 'Team A') : (teamB?.name || 'Team B') }}</div>
            </div>
          </div>
          <div 
            class="text-xl font-mono font-bold"
            :class="{
              'text-blue-300': timer.team === 'teamA',
              'text-red-300': timer.team === 'teamB',
              'text-yellow-400 animate-pulse': timer.remainingTime <= 10
            }"
          >
            {{ formatBoosterTime(timer.remainingTime) }}
          </div>
        </div>
      </div>
    </div>


  </div>
</template>

<style scoped>
@keyframes flash {
  0%, 100% { background-color: transparent; }
  50% { background-color: rgba(251, 191, 36, 0.3); }
}

.animate-flash {
  animation: flash 0.5s ease-in-out;
}

/* Booster activation animations */
@keyframes booster-activate {
  0% { 
    transform: scale(1) rotate(0deg);
    box-shadow: 0 0 0 rgba(34, 197, 94, 0);
  }
  25% { 
    transform: scale(1.1) rotate(5deg);
    box-shadow: 0 0 20px rgba(34, 197, 94, 0.6);
  }
  50% { 
    transform: scale(1.2) rotate(-5deg);
    box-shadow: 0 0 30px rgba(34, 197, 94, 0.8);
  }
  75% { 
    transform: scale(1.1) rotate(5deg);
    box-shadow: 0 0 20px rgba(34, 197, 94, 0.6);
  }
  100% { 
    transform: scale(1) rotate(0deg);
    box-shadow: 0 0 10px rgba(34, 197, 94, 0.4);
  }
}

@keyframes booster-pulse {
  0%, 100% { 
    box-shadow: 0 0 5px rgba(34, 197, 94, 0.4);
    transform: scale(1);
  }
  50% { 
    box-shadow: 0 0 15px rgba(34, 197, 94, 0.8);
    transform: scale(1.05);
  }
}

.booster-activating {
  animation: booster-activate 3s ease-in-out;
}

.booster-active {
  animation: booster-pulse 2s ease-in-out infinite;
}
</style>