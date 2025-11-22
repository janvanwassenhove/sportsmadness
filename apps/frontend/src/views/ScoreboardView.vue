<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import { useThemeStore } from '@/stores/theme'
import { supabase } from '@/lib/supabase'
import { SoundManager } from '@/lib/soundManager'

// Props for match ID
interface Props {
  id?: string
}

const props = defineProps<Props>()

interface Match {
  id: string
  team_a: string
  team_b: string
  score_a: number
  score_b: number
  pc_a?: number // Penalty corners for team A
  pc_b?: number // Penalty corners for team B
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

interface Booster {
  id: string
  name: string
  icon: string
  description?: string
  duration?: number
  expired?: boolean
  activated?: boolean
  isUsed?: boolean
}

interface Booster {
  id: string
  name: string
  icon: string
  description?: string
  duration?: number
  expired?: boolean
  activated?: boolean
  isUsed?: boolean
}

const { t } = useI18n()
const router = useRouter()
const themeStore = useThemeStore()

const currentMatch = ref<Match | null>(null)
const teams = ref<Record<string, Team>>({})
const loading = ref(true)
const maddieFlash = ref(false)
const showMatchSelector = ref(false)
const availableMatches = ref<Match[]>([])
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
let pollingInterval: number | null = null
let realtimeWorking = false

// Reactive variables for debug panel
const subscriptionStatus = ref<string>('Not connected')
const lastUpdateTime = ref<string>('Never')
const showDebugPanel = ref<boolean>(false)

// Fallback polling mechanism when real-time fails
function startPolling() {
  if (pollingInterval) {
    clearInterval(pollingInterval)
    pollingInterval = null
  }
  
  // Adjust polling frequency based on match status
  const getPollingInterval = () => {
    if (!currentMatch.value) return 3000
    return currentMatch.value.status === 'active' ? 1000 : 3000 // 1s for active, 3s for inactive
  }
  
  const poll = async () => {
    if (!currentMatch.value) {
      console.log('⚠️ No current match, stopping poll')
      return
    }
    
    try {
      console.log('📊 Polling for match updates...', currentMatch.value.id)
      const { data, error } = await supabase
        .from('matches')
        .select('*')
        .eq('id', currentMatch.value.id)
        .single()
      
      if (error) {
        console.error('❌ Polling error:', error)
        return
      }
      
      if (data) {
        // Check for ANY changes - be more aggressive with updates
        const timeDiff = Math.abs(data.time_left - currentMatch.value.time_left)
        const hasChanges = 
          data.score_a !== currentMatch.value.score_a ||
          data.score_b !== currentMatch.value.score_b ||
          (data.pc_a || 0) !== (currentMatch.value.pc_a || 0) ||
          (data.pc_b || 0) !== (currentMatch.value.pc_b || 0) ||
          data.status !== currentMatch.value.status ||
          timeDiff > 2 || // Sync for any time difference over 2 seconds
          JSON.stringify(data.boosters) !== JSON.stringify(currentMatch.value.boosters) ||
          JSON.stringify(data.cards) !== JSON.stringify(currentMatch.value.cards)
        
        if (hasChanges) {
          console.log('📊 Polling detected changes:', {
            old_scores: `${currentMatch.value.score_a} - ${currentMatch.value.score_b}`,
            new_scores: `${data.score_a} - ${data.score_b}`,
            old_pc: `${currentMatch.value.pc_a || 0} - ${currentMatch.value.pc_b || 0}`,
            new_pc: `${data.pc_a || 0} - ${data.pc_b || 0}`,
            old_time: currentMatch.value.time_left,
            new_time: data.time_left,
            time_diff: timeDiff,
            status: `${currentMatch.value.status} -> ${data.status}`,
            boosters_changed: JSON.stringify(data.boosters) !== JSON.stringify(currentMatch.value.boosters)
          })
          
          // Simulate the real-time update format
          const payload = {
            eventType: 'UPDATE',
            new: data,
            old: currentMatch.value
          }
          
          // Call the same handler that real-time would call
          handleRealtimeUpdate(payload)
        } else {
          console.log('📊 Polling: No changes detected')
        }
      }
    } catch (error) {
      console.error('❌ Polling failed:', error)
    }
  }
  
  console.log(`📊 Starting adaptive polling (${getPollingInterval()}ms interval)...`)
  
  // Use setInterval for more reliable polling
  pollingInterval = setInterval(poll, getPollingInterval()) as unknown as number
  
  // Do an immediate poll
  poll()
}

function stopPolling() {
  if (pollingInterval) {
    console.log('🛑 Stopping polling')
    clearInterval(pollingInterval)
    pollingInterval = null
  }
}

// Centralized function to handle match updates (from real-time or polling)
function handleRealtimeUpdate(payload: any) {
  // Update last update time
  lastUpdateTime.value = new Date().toLocaleTimeString()
  
  console.log('📡 *** SCOREBOARD RECEIVED UPDATE ***', payload)
  console.log('📡 Scoreboard received real-time update:', payload)
  
  // Normalize payload structure - Supabase uses different formats
  const eventType = payload.eventType || payload.event_type || 'UPDATE'
  const newData = payload.new || payload
  const oldData = payload.old || currentMatch.value
  
  console.log('📡 Normalized payload:', {
    eventType,
    newId: newData?.id,
    currentMatchId: currentMatch.value?.id,
    willUpdate: eventType === 'UPDATE' && currentMatch.value?.id === newData?.id,
    newScores: `${newData?.score_a || 0} - ${newData?.score_b || 0}`,
    currentScores: `${currentMatch.value?.score_a || 0} - ${currentMatch.value?.score_b || 0}`
  })
  
  // DETAILED BOOSTER COMPARISON DEBUG
  console.log('🔍 DETAILED BOOSTER COMPARISON:')
  console.log('🔍 Old boosters structure:', JSON.stringify(currentMatch.value?.boosters, null, 2))
  console.log('🔍 New boosters structure:', JSON.stringify(newData?.boosters, null, 2))

  if (eventType === 'UPDATE' || eventType === 'INSERT') {
    console.log('🚨 SCOREBOARD - Received update for match:', newData.id)
    
    const oldMaddie = currentMatch.value?.maddie || false
    const oldBoosters = currentMatch.value?.boosters
    
    // Track score changes
    const oldScoreA = currentMatch.value?.score_a || 0
    const oldScoreB = currentMatch.value?.score_b || 0
    const newScoreA = newData.score_a || 0
    const newScoreB = newData.score_b || 0
    
    // Track PC changes
    const oldPCA = currentMatch.value?.pc_a || 0
    const oldPCB = currentMatch.value?.pc_b || 0
    const newPCA = newData.pc_a || 0
    const newPCB = newData.pc_b || 0
    
    if (oldScoreA !== newScoreA || oldScoreB !== newScoreB) {
      console.log('🔢 SCOREBOARD - Score changed!', {
        old: `${oldScoreA} - ${oldScoreB}`,
        new: `${newScoreA} - ${newScoreB}`,
        teamA_change: newScoreA - oldScoreA,
        teamB_change: newScoreB - oldScoreB
      })
    }
    
    if (oldPCA !== newPCA || oldPCB !== newPCB) {
      console.log('🏒 SCOREBOARD - PC changed!', {
        old: `${oldPCA} - ${oldPCB}`,
        new: `${newPCA} - ${newPCB}`,
        teamA_change: newPCA - oldPCA,
        teamB_change: newPCB - oldPCB
      })
    }
    
    console.log('📡 Updating match state:', { 
      boosters: newData.boosters,
      selection_active: newData.boosters?.selection_active,
      selection_phase: newData.boosters?.selection_phase,
      teamA: newData.boosters?.teamA,
      teamB: newData.boosters?.teamB,
      oldBoosters: oldBoosters,
      scores: {
        old: `${oldScoreA} - ${oldScoreB}`,
        new: `${newScoreA} - ${newScoreB}`
      }
    })
    
    // Detect booster activation before updating the match
    detectBoosterActivation(oldBoosters, newData.boosters)
    
    // Store old values for sync comparison
    const oldTimeLeft = currentMatch.value?.time_left || 0
    const oldStatus = currentMatch.value?.status
    
    currentMatch.value = newData as Match
    
    // Sync timer if time changed OR status changed
    if (currentMatch.value.time_left !== oldTimeLeft || currentMatch.value.status !== oldStatus) {
      syncWithDatabaseUpdate(currentMatch.value.time_left)
    } else {
      initializeMatchPhase()
    }
    
    const overlayShould = currentMatch.value?.boosters?.selection_active === true
    console.log('📡 Match state updated, overlay should be:', overlayShould)
    
    // Enhanced debugging for booster state changes
    if (newData.boosters) {
      console.log('📡 Booster state change detected:', {
        selection_active: newData.boosters.selection_active,
        selection_phase: newData.boosters.selection_phase,
        teamA_exists: !!newData.boosters.teamA,
        teamB_exists: !!newData.boosters.teamB,
        teamA_length: newData.boosters.teamA?.length || 0,
        teamB_length: newData.boosters.teamB?.length || 0
      })
    }
    
    // Detect maddie activation
    detectMaddieActivation(oldMaddie, currentMatch.value.maddie)
  }
}

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
    console.log('📡 Loading boosters and maddies...')
    
    const [boostersResult, maddiesResult] = await Promise.all([
      supabase.from('boosters').select('*').order('title'),
      supabase.from('maddies').select('*').order('title')
    ])

    if (boostersResult.error) {
      console.error('Error loading boosters:', boostersResult.error)
      console.log('📡 Boosters loading failed - some features may not work properly')
    } else {
      availableBoosters.value = boostersResult.data.map(booster => ({
        id: booster.id,
        name: booster.title,
        icon: booster.icon || '⚡',
        description: booster.description,
        duration: booster.duration
      }))
      console.log('📡 Boosters loaded:', availableBoosters.value.length)
    }

    if (maddiesResult.error) {
      console.error('Error loading maddies:', maddiesResult.error)
      console.log('📡 Maddies loading failed - some features may not work properly')
    } else {
      availableMaddies.value = maddiesResult.data
      console.log('📡 Maddies loaded:', availableMaddies.value.length)
    }
  } catch (error) {
    console.error('Error loading boosters and maddies (auth-related):', error)
    console.log('📡 Continuing without boosters/maddies - check RLS policies for public access')
  }
}

const teamA = computed(() => currentMatch.value ? teams.value[currentMatch.value.team_a] : null)
const teamB = computed(() => currentMatch.value ? teams.value[currentMatch.value.team_b] : null)

// Available boosters per team - available vs used
const teamAAvailableBoosters = computed(() => {
  if (!availableBoosters.value.length || !currentMatch.value) return []
  
  const usedBoosterIds = currentMatch.value.boosters?.current_boosters?.teamA?.map((b: any) => b.id) || []
  
  return availableBoosters.value.map(booster => ({
    ...booster,
    isUsed: usedBoosterIds.includes(booster.id)
  }))
})

const teamBAvailableBoosters = computed(() => {
  if (!availableBoosters.value.length || !currentMatch.value) return []
  
  const usedBoosterIds = currentMatch.value.boosters?.current_boosters?.teamB?.map((b: any) => b.id) || []
  
  return availableBoosters.value.map(booster => ({
    ...booster,
    isUsed: usedBoosterIds.includes(booster.id)
  }))
})

// Check if any booster is in countdown or activation state
const isAnyBoosterCountingDown = computed(() => {
  return boosterCountdown.value?.active || false
})

const isAnyBoosterActivated = computed(() => {
  return boosterActivation.value?.active || false
})

// Check if any booster is currently running (has active timer)
const isAnyBoosterRunning = computed(() => {
  return Object.keys(activeBoosterTimers.value).length > 0
})

// Check if any maddie is active (countdown, activation display, or running)
const isAnyMaddieActive = computed(() => {
  return maddieCountdown.value?.active || 
         maddieActivation.value?.active || 
         activeMaddieTimer.value !== null
})

// Check if team boosters should be hidden (during countdown, activation, running, or maddie active)
const shouldHideTeamABoosters = computed(() => {
  return isAnyBoosterCountingDown.value || isAnyBoosterActivated.value || isAnyBoosterRunning.value || isAnyMaddieActive.value
})

const shouldHideTeamBBoosters = computed(() => {
  return isAnyBoosterCountingDown.value || isAnyBoosterActivated.value || isAnyBoosterRunning.value || isAnyMaddieActive.value
})

// Get boosters with their state for display (including expired/crossed out)
const teamABoostersWithState = computed(() => {
  const currentBoosters = currentMatch.value?.boosters?.current_boosters?.teamA || 
                         currentMatch.value?.boosters?.teamA || []
  
  return currentBoosters.map((booster: any) => ({
    ...booster,
    isExpired: booster.expired || false,
    isActivated: booster.activated || false
  }))
})

const teamBBoostersWithState = computed(() => {
  const currentBoosters = currentMatch.value?.boosters?.current_boosters?.teamB || 
                         currentMatch.value?.boosters?.teamB || []
  
  return currentBoosters.map((booster: any) => ({
    ...booster,
    isExpired: booster.expired || false,
    isActivated: booster.activated || false
  }))
})

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
      // Always decrement for smooth countdown - this is the PRIMARY timer
      currentMatch.value.time_left--
      
      // Update phase time
      if (phaseTimeLeft.value > 0) {
        phaseTimeLeft.value--
      }
      
      // Recalculate phase if needed
      calculateCurrentPhase()
      
      // Update last sync time to show timer is running
      lastSyncTime.value = Date.now()
      
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
    const oldTime = currentMatch.value.time_left
    const timeDiff = Math.abs(oldTime - newTimeLeft)
    
    // Only log and sync for significant differences to avoid interrupting smooth countdown
    if (timeDiff > 3) {
      console.log('🔄 Database sync detected significant time difference:', { 
        oldTime: oldTime, 
        newTime: newTimeLeft,
        timeDiff: timeDiff,
        threshold: 5,
        willSync: timeDiff > 5
      })
    }
    
    // Only sync for major differences to preserve smooth countdown
    const syncThreshold = 5 // Fixed threshold for all states
    
    if (timeDiff > syncThreshold) {
      console.log(`⚠️ Major timer correction needed - difference: ${timeDiff}s`)
      
      // Update local time to match database
      currentMatch.value.time_left = newTimeLeft
      lastSyncTime.value = Date.now()
      
      // Recalculate phase timing
      calculateCurrentPhase()
    } else {
      // For small differences, just update lastSyncTime to show we got an update
      // but don't override the smooth countdown
      lastSyncTime.value = Date.now()
    }
    
    // Only restart timer if match status requires it, not for time sync
    if (currentMatch.value.status === 'active' && !localTimer) {
      startLocalTimer()
    } else if (currentMatch.value.status !== 'active' && localTimer) {
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
  
  // Only show overlay if selection is explicitly active
  // Keep showing until selection_active becomes false (confirmation in MatchControl)
  // This prevents glitching during phase transitions or database updates
  const shouldShow = active === true
  
  console.log('🎰 Scoreboard booster overlay check:', {
    hasMatch: !!currentMatch.value,
    boosters: !!boosters,
    active,
    phase,
    shouldShow,
    debug_conditions: {
      active_is_true: active === true
    }
  })
  return shouldShow
})

// Development mode check
const isDevelopment = computed(() => {
  return import.meta.env.DEV
})

// Force close booster overlay (debug function)
function forceCloseBoosterOverlay() {
  console.log('🎰 Force closing booster overlay')
  if (currentMatch.value?.boosters) {
    currentMatch.value.boosters.selection_active = false
  }
}

// Toggle debug panel visibility
function toggleDebugPanel() {
  showDebugPanel.value = !showDebugPanel.value
  console.log('🔧 Debug panel toggled:', showDebugPanel.value ? 'shown' : 'hidden')
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
    
    // If a specific match ID is provided, load that match
    if (props.id) {
      console.log('📡 Loading specific match:', props.id)
      
      try {
        const { data: specificMatch, error: specificError } = await supabase
          .from('matches')
          .select('*')
          .eq('id', props.id)
          .single()

        if (specificError) {
          console.error('Error loading specific match:', specificError)
          console.log('📡 Attempting to continue with auth-independent approach...')
          // If specific match fails due to auth, show match selector
          await loadAvailableMatches()
          return
        }

        if (specificMatch) {
          currentMatch.value = specificMatch
          console.log('📡 Specific match loaded:', specificMatch.id)
          console.log('🚨 SCOREBOARD - Now watching match:', specificMatch.id)
          initializeMatchPhase()
          return
        }
      } catch (authError) {
        console.error('📡 Authentication-related error when loading match:', authError)
        console.log('📡 Scoreboard should work without authentication - this may be a RLS policy issue')
        // Continue execution to show empty state rather than failing completely
      }
    }

    // Check if there are multiple active/paused matches - if so, show selector
    const { data: runningMatches, error: runningError } = await supabase
      .from('matches')
      .select('*')
      .in('status', ['active', 'paused'])

    if (runningError) {
      console.error('Error loading running matches:', runningError)
    } else if (runningMatches && runningMatches.length > 1) {
      // Multiple running matches - show selector
      console.log('📡 Multiple running matches found, showing selector')
      availableMatches.value = runningMatches
      showMatchSelector.value = true
      return
    } else if (runningMatches && runningMatches.length === 1) {
      // Single running match - load it directly
      currentMatch.value = runningMatches[0]
      console.log('📡 Single running match loaded:', runningMatches[0].id)
      console.log('🚨 SCOREBOARD - Now watching match:', runningMatches[0].id)
      initializeMatchPhase()
      return
    }

    // No running matches, check for initialized pending matches
    const { data: pendingMatches, error: pendingError } = await supabase
      .from('matches')
      .select('*')
      .eq('status', 'pending')
      .order('created_at', { ascending: false })

    if (pendingError) {
      console.error('Error loading pending matches:', pendingError)
    } else if (pendingMatches && pendingMatches.length > 0) {
      // Filter initialized matches
      const initializedMatches = pendingMatches.filter(match => {
        const hasConfirmedBoosters = (
          match.boosters?.teamA?.length > 0 || 
          match.boosters?.teamB?.length > 0
        )
        const hasCards = Object.keys(match.cards || {}).length > 0
        const hasScores = match.score_a > 0 || match.score_b > 0
        const hasModifiedTime = match.time_left !== 1800
        
        return hasConfirmedBoosters || hasCards || hasScores || hasModifiedTime
      })

      if (initializedMatches.length > 1) {
        // Multiple initialized matches - show selector
        console.log('📡 Multiple initialized matches found, showing selector')
        availableMatches.value = initializedMatches
        showMatchSelector.value = true
        return
      } else if (initializedMatches.length === 1) {
        // Single initialized match - load it
        currentMatch.value = initializedMatches[0]
        initializeMatchPhase()
        console.log('📡 Single initialized match loaded:', initializedMatches[0].id)
        console.log('🚨 SCOREBOARD - Now watching match:', initializedMatches[0].id)
        return
      }

      // No initialized matches, check if we should show selector for all pending
      if (pendingMatches.length > 1) {
        console.log('� Multiple pending matches found, showing selector')
        availableMatches.value = pendingMatches
        showMatchSelector.value = true
        return
      } else {
        // Single pending match - load it as fallback
        currentMatch.value = pendingMatches[0]
        initializeMatchPhase()
        console.log('📡 Fallback to single pending match:', pendingMatches[0].id)
        return
      }
    }

    console.log('📡 No matches found to display')
    currentMatch.value = null
  } catch (error) {
    console.error('Error loading current match:', error)
    currentMatch.value = null
  }
}

async function loadAvailableMatches() {
  try {
    console.log('📡 Loading available matches...')
    
    const { data: matches, error } = await supabase
      .from('matches')
      .select('*')
      .in('status', ['active', 'paused', 'pending'])
      .order('status', { ascending: false }) // Active first, then paused, then pending
      .order('created_at', { ascending: false })

    if (error) {
      console.error('Error loading available matches:', error)
      console.log('📡 This may be due to RLS policies requiring authentication for public scoreboard access')
      return
    }

    availableMatches.value = matches || []
    console.log('📡 Loaded available matches:', matches?.length || 0)
    
    if (matches && matches.length > 1) {
      showMatchSelector.value = true
    } else if (matches && matches.length === 1) {
      selectMatch(matches[0])
    } else {
      console.log('📡 No active matches found')
    }
  } catch (error) {
    console.error('Error loading available matches (auth-related):', error)
    console.log('📡 Scoreboard should be publicly accessible - check RLS policies')
  }
}

function selectMatch(match: Match) {
  currentMatch.value = match
  showMatchSelector.value = false
  initializeMatchPhase()
  console.log('📡 Match selected:', match.id)
  console.log('🚨 SCOREBOARD - Now watching match:', match.id)
  
  // Update URL to include match ID
  if (props.id !== match.id) {
    router.replace(`/scoreboard/${match.id}`)
  }
}

function getMatchDisplayName(match: Match): string {
  const teamA = teams.value[match.team_a]
  const teamB = teams.value[match.team_b]
  return `${teamA?.name || 'Team A'} vs ${teamB?.name || 'Team B'}`
}

async function loadTeams() {
  try {
    console.log('📡 Loading teams...')
    
    const { data, error } = await supabase
      .from('teams')
      .select('*')

    if (error) {
      console.error('Error loading teams:', error)
      console.log('📡 Teams loading failed - scoreboard may show team IDs instead of names')
      return
    }

    const teamsMap: Record<string, Team> = {}
    data?.forEach(team => {
      teamsMap[team.id] = team
    })
    teams.value = teamsMap
    console.log('📡 Teams loaded:', Object.keys(teamsMap).length)
  } catch (error) {
    console.error('Error loading teams (auth-related):', error)
    console.log('📡 Continuing without team names - check RLS policies for public access')
  }
}

// Test function to manually check if real-time updates are working
async function testRealtimeConnection() {
  console.log('🧪 Testing real-time connection...')
  
  // Create a simple test channel
  const testChannel = supabase
    .channel('test-connection')
    .on('broadcast', { event: 'test' }, (payload) => {
      console.log('✅ Real-time is working! Received test broadcast:', payload)
    })
    .subscribe((status) => {
      console.log('🧪 Test channel status:', status)
      if (status === 'SUBSCRIBED') {
        console.log('✅ Test channel subscribed successfully')
        // Send a test message
        testChannel.send({
          type: 'broadcast',
          event: 'test',
          payload: { message: 'Hello from scoreboard!' }
        })
        
        // Clean up after 2 seconds
        setTimeout(() => {
          testChannel.unsubscribe()
          console.log('🧪 Test channel cleaned up')
        }, 2000)
      }
    })
}

// Add to mounted for testing
function testDatabaseUpdate() {
  console.log('🧪 Testing direct database update...')
  if (currentMatch.value) {
    supabase
      .from('matches')
      .update({ last_updated: new Date().toISOString() })
      .eq('id', currentMatch.value.id)
      .then(result => {
        console.log('🧪 Test update result:', result)
      })
  }
}

// Force a single poll attempt for testing
async function forcePollOnce() {
  console.log('🔄 Manual poll triggered')
  if (!currentMatch.value) {
    console.log('❌ No current match to poll')
    return
  }
  
  try {
    const { data, error } = await supabase
      .from('matches')
      .select('*')
      .eq('id', currentMatch.value.id)
      .single()
    
    if (error) {
      console.error('❌ Manual poll error:', error)
      return
    }
    
    if (data) {
      console.log('📊 Manual poll data received:', data)
      // Check if data has changed
      const hasChanges = 
        data.score_a !== currentMatch.value.score_a ||
        data.score_b !== currentMatch.value.score_b ||
        (data.pc_a || 0) !== (currentMatch.value.pc_a || 0) ||
        (data.pc_b || 0) !== (currentMatch.value.pc_b || 0) ||
        data.status !== currentMatch.value.status ||
        data.time_left !== currentMatch.value.time_left ||
        JSON.stringify(data.boosters) !== JSON.stringify(currentMatch.value.boosters)
      
      if (hasChanges) {
        console.log('📊 Manual poll detected changes - updating!')
        const payload = {
          eventType: 'UPDATE',
          new: data,
          old: currentMatch.value
        }
        handleRealtimeUpdate(payload)
      } else {
        console.log('📊 Manual poll - no changes detected')
      }
    }
  } catch (error) {
    console.error('❌ Manual poll failed:', error)
  }
}

function setupRealtimeSubscription() {
  console.log('🔧 setupRealtimeSubscription called', { 
    hasCurrentMatch: !!currentMatch.value, 
    matchId: currentMatch.value?.id,
    matchStatus: currentMatch.value?.status
  })
  
  if (!currentMatch.value) {
    console.log('❌ No current match - cannot set up subscription, starting polling anyway')
    startPolling()
    return
  }
  
  console.log('🔧 Setting up ScoreboardView real-time subscription for match:', currentMatch.value.id)
  
  // Unsubscribe from previous subscription if exists
  if (realtimeSubscription) {
    console.log('🔧 Unsubscribing from previous subscription')
    realtimeSubscription.unsubscribe()
    realtimeSubscription = null
  }
  
  const channelName = `match_${currentMatch.value.id}`
  console.log('📡 Creating channel:', channelName)
  
  // Test connection first
  realtimeSubscription = supabase
    .channel(channelName)
    .on(
      'postgres_changes',
      {
        event: '*', // Listen to all events first for debugging
        schema: 'public',
        table: 'matches',
        filter: `id=eq.${currentMatch.value.id}`
      },
      (payload) => {
        console.log('🎯 ScoreboardView received real-time payload:', payload)
        console.log('🎯 ScoreboardView FULL payload object:', JSON.stringify(payload, null, 2))
        realtimeWorking = true
        handleRealtimeUpdate(payload)
      }
    )
    .subscribe((status) => {
      console.log('📡 ScoreboardView subscription status:', status)
      subscriptionStatus.value = status
      
      if (status === 'SUBSCRIBED') {
        console.log('✅ ScoreboardView successfully subscribed to real-time updates')
        
        // Start polling as backup immediately
        console.log('🔄 Starting polling as backup')
        startPolling()
        
        // Keep polling active for reliability - don't stop it
        console.log('✅ Keeping polling active for reliability')
      } else if (status === 'CHANNEL_ERROR') {
        console.error('❌ ScoreboardView subscription error')
        subscriptionStatus.value = 'Error'
        startPolling() // Start polling immediately on error
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
  
  // Play countdown start sound
  playCountdownSound()
  
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
    countdown: 15,
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
      
      // Play end sound when countdown finishes (but this is for activation, not ending)
      playBoosterSound(booster)
      
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
  
  // Play countdown start sound
  playCountdownSound()
  
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
    countdown: 15
  }
  
  // Start countdown timer
  maddieCountdownInterval = setInterval(() => {
    if (maddieCountdown.value && maddieCountdown.value.countdown > 1) {
      maddieCountdown.value.countdown--
      console.log(`⏰ Maddie countdown: ${maddieCountdown.value.countdown}`)
    } else {
      // Countdown finished - trigger actual activation
      console.log('🚀 Maddie countdown finished - triggering maddie activation!')
      
      // Play sound when countdown ends
      playMaddieSound()
      
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
        
        // Play end sound when booster timer expires
        playBoosterEndSound()
        
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
        // Play end sound when maddie timer expires
        playMaddieEndSound()
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
  console.log('🔍 SCOREBOARD - detectBoosterActivation called:', { oldBoosters, newBoosters })
  console.log('🔍 SCOREBOARD - detectBoosterActivation TRIGGERED')
  
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
      console.log('🎯 Scoreboard detected booster selection complete - waiting for admin confirmation')
      
      // DO NOT auto-close or fallback confirm
      // The overlay will remain visible until MatchControlView explicitly confirms
      // and sets selection_active to false
      // This prevents glitching between views during phase transitions
      
      console.log('✅ Overlay will remain visible until explicit confirmation in MatchControl')
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
    await SoundManager.playSound('/sounds/selection.mp3', 1.5)
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

async function playCountdownSound() {
  try {
    // Play countdown start sound when booster or maddie countdown begins
    await SoundManager.playSound('/sounds/countdown.wav', 1.0)
    console.log('🔊 Playing countdown start sound')
  } catch (error) {
    console.log('🔊 Countdown sound not available, trying fallback')
    try {
      // Fallback to a tick sound for countdown start
      await SoundManager.playSound('/sounds/tick.mp3', 0.5)
    } catch (fallbackError) {
      console.warn('🔊 No countdown sound available')
    }
  }
}

// New functions for ending sounds
async function playMaddieEndSound() {
  try {
    console.log('🔊 Playing maddie end sound')
    await SoundManager.playSound('/sounds/end-maddie.wav')
  } catch (error) {
    console.warn('End maddie sound not available, using default')
    // Fallback to regular maddie sound
    playMaddieSound()
  }
}

async function playBoosterEndSound() {
  try {
    console.log('🔊 Playing booster end sound')
    await SoundManager.playSound('/sounds/end-booster.wav')
  } catch (error) {
    console.warn('End booster sound not available, using default')
    // Fallback to regular booster sound
    playBoosterSound()
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
  
  // Add debug logging for production routing
  console.log('🏒 Scoreboard mounting on:', {
    url: window.location.href,
    pathname: window.location.pathname,
    search: window.location.search,
    hash: window.location.hash,
    base_url: import.meta.env.BASE_URL,
    is_production: import.meta.env.PROD,
    props_id: props.id
  })
  
  try {
    await Promise.all([loadCurrentMatch(), loadTeams(), loadBoostersAndMaddies()])
    console.log('✅ Scoreboard data loaded successfully')
    // setupRealtimeSubscription() is now handled by the watch
  } catch (error) {
    console.error('❌ CRITICAL: Failed to initialize Scoreboard:', error)
    console.log('⚠️ Scoreboard will attempt to continue with limited functionality')
    
    // Add more specific error handling for GitHub Pages
    if (error instanceof Error) {
      console.log('Error details:', {
        name: error.name,
        message: error.message,
        stack: error.stack?.split('\n')[0]
      })
    }
    
    // Don't show alert on scoreboard as it's public-facing
  } finally {
    // ALWAYS set loading to false, even if errors occurred
    loading.value = false
    console.log('✅ Scoreboard initialization complete (loading state cleared)')
  }
})

onUnmounted(() => {
  if (realtimeSubscription) {
    realtimeSubscription.unsubscribe()
  }
  stopLocalTimer()
  stopPolling() // Stop polling fallback
  
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
          <div v-else class="text-6xl mb-4">�</div>
        </div>
        <h2 class="hc-title mb-4">
          {{ $t('scoreboard.noActiveMatch') }}
        </h2>
        <p class="hc-body">
          {{ $t('scoreboard.checkBackMessage') }}
        </p>
      </div>
    </div>

    <!-- Booster Selection Overlay - Full Screen -->
    <div 
      v-if="shouldShowBoosterOverlay"
      class="fixed inset-0 bg-gradient-to-r from-[#121238] to-[#478dcb] flex items-center justify-center z-50"
    >
      <div class="text-center w-full h-full flex flex-col justify-center px-4 py-4">
        <!-- Main title - Adaptive size when spinning -->
        <h1 :class="currentMatch?.boosters?.is_spinning ? 'text-5xl lg:text-6xl xl:text-7xl mb-4 lg:mb-6' : 'text-8xl lg:text-9xl xl:text-[8rem] mb-8 lg:mb-12'" 
            class="font-bold text-white drop-shadow-2xl">
          🎰 {{ $t('scoreboard.boosterSelection') }} 🎰
        </h1>
        
        <!-- Phase status - Adaptive size when spinning -->
        <div :class="currentMatch?.boosters?.is_spinning ? 'text-2xl lg:text-3xl xl:text-4xl mb-4 lg:mb-6' : 'text-4xl lg:text-5xl xl:text-6xl mb-8 lg:mb-12'" 
             class="font-bold text-white drop-shadow-xl">
          {{ getBoosterSelectionPhaseText() }}
        </div>
        
        <!-- Slot Machine Animation - Compact when spinning -->
        <div v-if="currentMatch?.boosters?.is_spinning" class="mb-4 lg:mb-6">
          <div class="text-xl lg:text-2xl xl:text-3xl font-bold text-yellow-300 mb-3 lg:mb-4 drop-shadow-lg">
            {{ $t('scoreboard.spinningFor', { team: currentMatch.boosters.current_team === 'A' ? teamA?.name : teamB?.name }) }}
          </div>
          
          <!-- Slot Machine Display - Compact -->
          <div class="mx-auto bg-gradient-to-b from-yellow-600 to-yellow-800 rounded-3xl p-6 lg:p-8 max-w-3xl shadow-2xl border-6 border-yellow-500 animate-pulse">
            <div class="bg-black rounded-2xl p-4 lg:p-6 mb-3 border-3 border-yellow-400">
              <div class="text-center">
                <div class="text-[6rem] lg:text-[8rem] xl:text-[10rem] mb-2 lg:mb-3 animate-bounce drop-shadow-2xl" style="animation-duration: 0.3s;">
                  {{ availableBoosters[currentMatch.boosters.spinning_slot || 0]?.icon || '🎲' }}
                </div>
                <div class="text-2xl lg:text-3xl xl:text-4xl font-bold text-yellow-300 animate-pulse mb-2 drop-shadow-lg">
                  {{ availableBoosters[currentMatch.boosters.spinning_slot || 0]?.name || 'Spinning...' }}
                </div>
                <div class="text-lg lg:text-xl xl:text-2xl text-yellow-200 mt-2 drop-shadow-sm">
                  {{ availableBoosters[currentMatch.boosters.spinning_slot || 0]?.description || 'Rolling the dice...' }}
                </div>
              </div>
            </div>
            <div class="text-center text-yellow-100 font-bold text-xl lg:text-2xl xl:text-3xl animate-pulse drop-shadow-lg">
              {{ $t('scoreboard.hockeyCasino') }}
            </div>
            <div class="text-center text-yellow-300 text-lg lg:text-xl xl:text-2xl mt-2 drop-shadow-sm">
              {{ $t('scoreboard.boosterSelectionLabel') }}
            </div>
          </div>
        </div>
        
        <!-- Team Boosters Display - Compact when spinning -->
        <div :class="currentMatch?.boosters?.is_spinning ? 'gap-4 lg:gap-6' : 'gap-8 lg:gap-12'" 
             class="grid grid-cols-1 xl:grid-cols-2 max-w-7xl mx-auto w-full">
          <!-- Team A Boosters -->
          <div :class="currentMatch?.boosters?.is_spinning ? 'p-4 lg:p-6' : 'p-8 lg:p-12'" 
               class="bg-white/10 rounded-3xl border-4 border-blue-500/50 backdrop-blur-sm shadow-2xl">
            <h3 :class="currentMatch?.boosters?.is_spinning ? 'text-2xl lg:text-3xl xl:text-4xl mb-3 lg:mb-4' : 'text-4xl lg:text-5xl xl:text-6xl mb-6 lg:mb-8'" 
                class="font-bold text-blue-300 drop-shadow-lg">{{ teamA?.name || 'Team A' }}</h3>
            <div v-if="currentMatch?.boosters?.current_boosters?.teamA && currentMatch.boosters.current_boosters.teamA.length > 0" 
                 :class="currentMatch?.boosters?.is_spinning ? 'space-y-2 lg:space-y-3' : 'space-y-4 lg:space-y-6'"
                 class="">
              <div 
                v-for="(booster, index) in currentMatch.boosters.current_boosters.teamA" 
                :key="index"
                :class="currentMatch?.boosters?.is_spinning ? 'p-3 lg:p-4' : 'p-6 lg:p-8'"
                class="bg-blue-500/20 rounded-2xl border-2 border-blue-400/30 shadow-lg"
              >
                <div :class="currentMatch?.boosters?.is_spinning ? 'text-lg lg:text-xl xl:text-2xl mb-1' : 'text-2xl lg:text-3xl xl:text-4xl mb-2'" 
                     class="font-bold text-white drop-shadow-sm">{{ booster.icon }} {{ booster.name }}</div>
                <div :class="currentMatch?.boosters?.is_spinning ? 'text-sm lg:text-base xl:text-lg' : 'text-lg lg:text-xl xl:text-2xl'" 
                     class="text-blue-200 drop-shadow-sm">{{ booster.description?.length > 150 ? booster.description.substring(0, 150) + '...' : booster.description }}</div>
              </div>
            </div>
            <div v-else :class="currentMatch?.boosters?.is_spinning ? 'text-lg lg:text-xl xl:text-2xl' : 'text-2xl lg:text-3xl xl:text-4xl'" 
                 class="text-blue-300 italic drop-shadow-sm">{{ $t('scoreboard.waitingForBoosters') }}</div>
          </div>
          
          <!-- Team B Boosters -->
          <div :class="currentMatch?.boosters?.is_spinning ? 'p-4 lg:p-6' : 'p-8 lg:p-12'" 
               class="bg-white/10 rounded-3xl border-4 border-red-500/50 backdrop-blur-sm shadow-2xl">
            <h3 :class="currentMatch?.boosters?.is_spinning ? 'text-2xl lg:text-3xl xl:text-4xl mb-3 lg:mb-4' : 'text-4xl lg:text-5xl xl:text-6xl mb-6 lg:mb-8'" 
                class="font-bold text-red-300 drop-shadow-lg">{{ teamB?.name || 'Team B' }}</h3>
            <div v-if="currentMatch?.boosters?.current_boosters?.teamB && currentMatch.boosters.current_boosters.teamB.length > 0" 
                 :class="currentMatch?.boosters?.is_spinning ? 'space-y-2 lg:space-y-3' : 'space-y-4 lg:space-y-6'"
                 class="">
              <div 
                v-for="(booster, index) in currentMatch.boosters.current_boosters.teamB" 
                :key="index"
                :class="currentMatch?.boosters?.is_spinning ? 'p-3 lg:p-4' : 'p-6 lg:p-8'"
                class="bg-red-500/20 rounded-2xl border-2 border-red-400/30 shadow-lg"
              >
                <div :class="currentMatch?.boosters?.is_spinning ? 'text-lg lg:text-xl xl:text-2xl mb-1' : 'text-2xl lg:text-3xl xl:text-4xl mb-2'" 
                     class="font-bold text-white drop-shadow-sm">{{ booster.icon }} {{ booster.name }}</div>
                <div :class="currentMatch?.boosters?.is_spinning ? 'text-sm lg:text-base xl:text-lg' : 'text-lg lg:text-xl xl:text-2xl'" 
                     class="text-red-200 drop-shadow-sm">{{ booster.description?.length > 150 ? booster.description.substring(0, 150) + '...' : booster.description }}</div>
              </div>
            </div>
            <div v-else :class="currentMatch?.boosters?.is_spinning ? 'text-lg lg:text-xl xl:text-2xl' : 'text-2xl lg:text-3xl xl:text-4xl'" 
                 class="text-red-300 italic drop-shadow-sm">{{ $t('scoreboard.waitingForBoosters') }}</div>
          </div>
        </div>
        
        <!-- Auto-closing message - Adaptive -->
        <div v-if="currentMatch?.boosters?.selection_phase === 'complete'" :class="currentMatch?.boosters?.is_spinning ? 'mt-4 lg:mt-6' : 'mt-8 lg:mt-12'">
          <div :class="currentMatch?.boosters?.is_spinning ? 'text-xl lg:text-2xl xl:text-3xl' : 'text-3xl lg:text-4xl xl:text-5xl'" 
               class="text-green-400 font-bold drop-shadow-lg">
            {{ $t('scoreboard.boostersConfirmed') }}
          </div>
          <div :class="currentMatch?.boosters?.is_spinning ? 'text-lg lg:text-xl xl:text-2xl mt-2' : 'text-xl lg:text-2xl xl:text-3xl mt-4'" 
               class="text-white/70 drop-shadow-sm">
            {{ $t('scoreboard.returningToScoreboard') }}
          </div>
        </div>
      </div>
    </div>

    <div v-else class="h-screen flex flex-col">
      <!-- Minimal Header -->
      <div class="header-section text-center py-2">
        <div class="flex items-center justify-center mb-2">
          <!-- Theme Logo with proper background for dark logos -->
          <div v-if="themeStore.currentTheme?.logo" class="logo-bg-light mr-3">
            <img 
              :src="themeStore.currentTheme.logo" 
              :alt="themeStore.currentTheme.name"
              class="w-12 h-12"
            />
          </div>
          <div v-else class="text-3xl mr-3">�</div>
          
          <!-- Title with clean HC Lokeren styling -->
          <h1 class="text-2xl font-bold">
            {{ themeStore.currentTheme?.name || $t('home.title') }}
          </h1>
        </div>
        
        <!-- Live indicator -->
        <div class="flex items-center justify-center space-x-2">
          <div class="w-3 h-3 bg-red-500 rounded-full animate-pulse"></div>
          <span class="text-base font-medium font-theme-text"
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
      </div>

      <!-- Active Boosters Overlay (Full Screen) -->
      <div v-if="currentMatch?.boosters && (currentMatch.boosters.teamA?.some((b: any) => b.activated && !b.expired) || currentMatch.boosters.teamB?.some((b: any) => b.activated && !b.expired))" 
           class="fixed inset-0 flex items-center justify-center pointer-events-none z-44">
        <!-- Enhanced gradient backdrop -->
        <div class="absolute inset-0 bg-gradient-to-br from-green-900/80 to-emerald-600/80 backdrop-blur-md"></div>
        
        <!-- Main content container - Full width/height -->
        <div class="relative text-center w-full h-full flex flex-col justify-center px-8">
          <!-- Title - Much larger -->
          <div class="text-8xl lg:text-9xl xl:text-[8rem] font-bold text-white mb-12 drop-shadow-2xl animate-pulse"
               style="text-shadow: 6px 6px 12px rgba(0,0,0,0.9)">
            ⚡ ACTIVE BOOSTERS ⚡
          </div>
          
          <!-- Grid for multiple boosters - Full width -->
          <div class="grid grid-cols-1 xl:grid-cols-2 gap-12 w-full max-w-none px-4">
            <!-- Team A Active Boosters -->
            <div v-if="currentMatch.boosters.teamA?.some((b: any) => b.activated && !b.expired)" 
                 class="space-y-8">
              <div class="text-6xl lg:text-7xl xl:text-8xl font-bold text-blue-300 mb-8 drop-shadow-xl"
                   style="text-shadow: 4px 4px 8px rgba(0,0,0,0.9)">
                {{ teamA?.name || 'Team A' }}
              </div>
              <div class="space-y-8">
                <template v-for="booster in currentMatch.boosters.teamA" :key="`overlay-a-${booster.id}`">
                  <div v-if="booster.activated && !booster.expired" 
                       class="bg-green-700/95 rounded-3xl p-8 lg:p-12 border-4 border-green-300 shadow-2xl relative overflow-hidden transform hover:scale-105 transition-transform">
                    <!-- Enhanced sparkle overlay -->
                    <div class="absolute inset-0 bg-gradient-to-r from-green-500/30 to-emerald-500/30 animate-pulse rounded-3xl"></div>
                    <div class="absolute inset-0 bg-black/20 rounded-3xl"></div>
                    
                    <div class="relative z-10 flex items-center justify-between text-white">
                      <div class="flex items-center space-x-6 lg:space-x-8">
                        <span class="text-8xl lg:text-9xl xl:text-[8rem] animate-bounce drop-shadow-2xl" 
                              style="filter: drop-shadow(0 0 30px rgba(255,255,255,0.8))">
                          {{ booster.icon }}
                        </span>
                        <div class="text-left">
                          <div class="text-4xl lg:text-5xl xl:text-6xl font-bold drop-shadow-xl" 
                               style="text-shadow: 4px 4px 8px rgba(0,0,0,0.9)">
                            {{ booster.name }}
                          </div>
                          <div class="text-2xl lg:text-3xl xl:text-4xl opacity-90 drop-shadow-lg mt-2" 
                               style="text-shadow: 3px 3px 6px rgba(0,0,0,0.8)">
                            {{ booster.description?.length > 150 ? booster.description.substring(0, 150) + '...' : (booster.description || 'Active boost effect') }}
                          </div>
                        </div>
                      </div>
                      
                      <!-- Enhanced timer display -->
                      <div class="text-right">
                        <div v-if="booster.duration && getBoosterTimer('teamA', booster.id)" 
                             class="bg-yellow-500 text-black px-8 py-4 lg:px-10 lg:py-6 rounded-3xl text-3xl lg:text-4xl xl:text-5xl font-bold font-mono animate-pulse shadow-xl border-4 border-yellow-300">
                          ⏰ {{ formatBoosterTime(getBoosterTimer('teamA', booster.id)?.remainingTime || 0) }}
                        </div>
                        <div v-else-if="!booster.duration" 
                             class="bg-orange-500 text-white px-8 py-4 lg:px-10 lg:py-6 rounded-3xl text-3xl lg:text-4xl xl:text-5xl font-bold animate-bounce shadow-xl border-4 border-orange-300">
                          ⚡ INSTANT
                        </div>
                      </div>
                    </div>
                    
                    <!-- Enhanced visual effects -->
                    <div class="absolute top-4 right-4 text-yellow-300 text-4xl lg:text-5xl animate-spin drop-shadow-xl">✨</div>
                  </div>
                </template>
              </div>
            </div>
            
            <!-- Team B Active Boosters -->
            <div v-if="currentMatch.boosters.teamB?.some((b: any) => b.activated && !b.expired)" 
                 class="space-y-8">
              <div class="text-6xl lg:text-7xl xl:text-8xl font-bold text-red-300 mb-8 drop-shadow-xl"
                   style="text-shadow: 4px 4px 8px rgba(0,0,0,0.9)">
                {{ teamB?.name || 'Team B' }}
              </div>
              <div class="space-y-8">
                <template v-for="booster in currentMatch.boosters.teamB" :key="`overlay-b-${booster.id}`">
                  <div v-if="booster.activated && !booster.expired" 
                       class="bg-green-700/95 rounded-3xl p-8 lg:p-12 border-4 border-green-300 shadow-2xl relative overflow-hidden transform hover:scale-105 transition-transform">
                    <!-- Enhanced sparkle overlay -->
                    <div class="absolute inset-0 bg-gradient-to-r from-green-500/30 to-emerald-500/30 animate-pulse rounded-3xl"></div>
                    <div class="absolute inset-0 bg-black/20 rounded-3xl"></div>
                    
                    <div class="relative z-10 flex items-center justify-between text-white">
                      <div class="flex items-center space-x-6 lg:space-x-8">
                        <span class="text-8xl lg:text-9xl xl:text-[8rem] animate-bounce drop-shadow-2xl" 
                              style="filter: drop-shadow(0 0 30px rgba(255,255,255,0.8))">
                          {{ booster.icon }}
                        </span>
                        <div class="text-left">
                          <div class="text-4xl lg:text-5xl xl:text-6xl font-bold drop-shadow-xl" 
                               style="text-shadow: 4px 4px 8px rgba(0,0,0,0.9)">
                            {{ booster.name }}
                          </div>
                          <div class="text-2xl lg:text-3xl xl:text-4xl opacity-90 drop-shadow-lg mt-2" 
                               style="text-shadow: 3px 3px 6px rgba(0,0,0,0.8)">
                            {{ booster.description?.length > 150 ? booster.description.substring(0, 150) + '...' : (booster.description || 'Active boost effect') }}
                          </div>
                        </div>
                      </div>
                      
                      <!-- Enhanced timer display -->
                      <div class="text-right">
                        <div v-if="booster.duration && getBoosterTimer('teamB', booster.id)" 
                             class="bg-yellow-500 text-black px-8 py-4 lg:px-10 lg:py-6 rounded-3xl text-3xl lg:text-4xl xl:text-5xl font-bold font-mono animate-pulse shadow-xl border-4 border-yellow-300">
                          ⏰ {{ formatBoosterTime(getBoosterTimer('teamB', booster.id)?.remainingTime || 0) }}
                        </div>
                        <div v-else-if="!booster.duration" 
                             class="bg-orange-500 text-white px-8 py-4 lg:px-10 lg:py-6 rounded-3xl text-3xl lg:text-4xl xl:text-5xl font-bold animate-bounce shadow-xl border-4 border-orange-300">
                          ⚡ INSTANT
                        </div>
                      </div>
                    </div>
                    
                    <!-- Enhanced visual effects -->
                    <div class="absolute top-4 right-4 text-yellow-300 text-4xl lg:text-5xl animate-spin drop-shadow-xl">✨</div>
                  </div>
                </template>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Maddie Active Overlay (Full Screen) -->
      <div 
        v-if="currentMatch?.maddie && ((typeof currentMatch.maddie === 'object' && currentMatch.maddie.activated) || (typeof currentMatch.maddie === 'boolean' && currentMatch.maddie))"
        class="fixed inset-0 flex items-center justify-center pointer-events-none z-45"
      >
        <!-- Enhanced gradient backdrop for full screen impact -->
        <div class="absolute inset-0 bg-gradient-to-br from-purple-900/90 to-purple-600/90 backdrop-blur-xl"></div>
        
        <!-- Main content container - Full width/height with proper spacing -->
        <div class="relative text-center w-full h-full flex flex-col justify-between px-4 py-8 lg:py-12">
          <!-- Top spacer -->
          <div class="flex-shrink-0"></div>
          
          <!-- Main content area -->
          <div class="flex-1 flex flex-col justify-center space-y-4 lg:space-y-6 xl:space-y-8 min-h-0">
            <!-- Maddie icon with enhanced glow -->
            <div class="text-[8rem] lg:text-[10rem] xl:text-[12rem] animate-pulse drop-shadow-2xl flex-shrink-0" 
                 style="filter: drop-shadow(0 0 50px rgba(255,255,255,0.9)) drop-shadow(0 0 100px rgba(255,255,255,0.5))">
              {{ (currentMatch && typeof currentMatch.maddie === 'object') ? currentMatch.maddie.icon || '📢' : '📢' }}
            </div>
            
            <!-- "MADDIE EFFECT ACTIVE" - Large text -->
            <div class="text-4xl lg:text-6xl xl:text-7xl font-bold text-white drop-shadow-2xl animate-pulse flex-shrink-0"
                 style="text-shadow: 6px 6px 12px rgba(0,0,0,0.9)">
              MADDIE EFFECT ACTIVE
            </div>
            
            <!-- Maddie name container - Enhanced and large -->
            <div class="text-2xl lg:text-4xl xl:text-5xl font-bold px-8 py-4 lg:px-12 lg:py-6 rounded-3xl border-4 backdrop-blur-lg bg-purple-700/90 border-purple-200 text-white shadow-2xl max-w-4xl mx-auto flex-shrink-0"
                 style="box-shadow: 0 16px 64px rgba(0,0,0,0.7)">
              {{ (currentMatch && typeof currentMatch.maddie === 'object') ? (currentMatch.maddie.name || currentMatch.maddie.title || 'Special Effect') : 'Special Effect' }}
            </div>
            
            <!-- Description - Large if available -->
            <div 
              v-if="currentMatch && typeof currentMatch.maddie === 'object' && (currentMatch.maddie.description || currentMatch.maddie.subtitle)"
              class="text-lg lg:text-2xl xl:text-3xl text-purple-100 drop-shadow-xl max-w-5xl mx-auto flex-shrink-0 leading-relaxed"
              style="text-shadow: 4px 4px 8px rgba(0,0,0,0.8)"
            >
              {{ currentMatch.maddie.description || currentMatch.maddie.subtitle }}
            </div>
          </div>
          
          <!-- Timer display - Fixed at bottom -->
          <div class="flex-shrink-0 pb-4 lg:pb-8">
            <div 
              v-if="activeMaddieTimer"
              class="text-2xl lg:text-3xl xl:text-4xl text-purple-100 font-semibold text-center bg-purple-800/90 rounded-2xl px-8 py-4 lg:px-12 lg:py-6 border-4 border-purple-300 shadow-2xl max-w-3xl mx-auto"
              style="box-shadow: 0 16px 64px rgba(0,0,0,0.6)"
            >
              <div class="flex items-center justify-center space-x-4 lg:space-x-6">
                <span class="text-yellow-300 animate-pulse text-3xl lg:text-4xl xl:text-5xl drop-shadow-2xl">⏰</span>
                <span class="font-mono text-4xl lg:text-5xl xl:text-6xl text-white drop-shadow-2xl" 
                      style="text-shadow: 4px 4px 8px rgba(0,0,0,0.9)">
                  {{ formatMaddieTime(activeMaddieTimer.remainingTime) }}
                </span>
                <span class="text-lg lg:text-xl xl:text-2xl text-purple-200 drop-shadow-lg">remaining</span>
              </div>
            </div>
            <div 
              v-else-if="currentMatch && typeof currentMatch.maddie === 'object' && currentMatch.maddie.duration"
              class="text-xl lg:text-2xl xl:text-3xl text-purple-200 font-semibold text-center drop-shadow-xl"
              style="text-shadow: 4px 4px 8px rgba(0,0,0,0.8)"
            >
              ⏱️ Duration: {{ currentMatch.maddie.duration }}s
            </div>
          </div>
        </div>
      </div>



      <!-- Main Scoreboard - Full Screen -->
      <div class="flex-1 flex items-center justify-center px-4">
        <div class="grid grid-cols-3 gap-4 w-full h-full max-h-96">
          <!-- Team A -->
          <div class="text-center flex flex-col justify-center">
            <div class="p-2">
              <!-- Selected Boosters for Team A -->
              <div v-if="!shouldHideTeamABoosters && ((currentMatch?.boosters?.current_boosters?.teamA?.length > 0) || (currentMatch?.boosters?.teamA?.length > 0))" class="mb-1">
                <div class="flex flex-wrap justify-center gap-4 lg:gap-6">
                  <!-- Display boosters with state management -->
                  <div 
                    v-for="booster in teamABoostersWithState" 
                    :key="booster.id || booster.name"
                    class="relative transition-all duration-300 min-w-24 lg:min-w-32"
                    :class="{
                      'opacity-60 scale-95': booster.isExpired,
                      'bg-blue-600/50 rounded-2xl p-4 lg:p-6 border-3 border-blue-300/70 shadow-xl backdrop-blur-sm': !booster.isExpired,
                      'bg-blue-600/30 rounded-2xl p-4 lg:p-6 border-3 border-blue-300/40 shadow-lg backdrop-blur-sm': booster.isExpired
                    }"
                  >
                    <div class="text-center">
                      <div class="text-4xl lg:text-5xl xl:text-6xl mb-3 drop-shadow-lg"
                           :class="{ 'opacity-50': booster.isExpired }">
                        {{ booster.icon }}
                      </div>
                      <div class="text-base lg:text-lg xl:text-xl font-bold text-white drop-shadow-md"
                           :class="{ 'opacity-50': booster.isExpired }">
                        {{ booster.name }}
                      </div>
                    </div>
                    <!-- Cross-out effect for expired boosters -->
                    <div 
                      v-if="booster.isExpired" 
                      class="absolute inset-0 flex items-center justify-center bg-black/20 rounded-2xl"
                    >
                      <div class="text-red-500 text-6xl lg:text-7xl xl:text-8xl font-bold opacity-90 transform rotate-12">✗</div>
                    </div>
                  </div>
                </div>
              </div>
              
              <h2 class="text-4xl lg:text-6xl xl:text-8xl font-bold mb-4">
                {{ teamA?.name || 'Team A' }}
              </h2>
              <div class="text-8xl lg:text-9xl xl:text-[12rem] font-black mb-4">
                {{ currentMatch?.score_a || 0 }}
              </div>
              
              <!-- Team A Penalty Corners -->
              <div class="text-yellow-300 text-2xl lg:text-4xl xl:text-6xl font-bold mb-4">
                PC: {{ currentMatch?.pc_a || 0 }}
              </div>
              
              <!-- Team A Active Penalties (simplified) -->
              <div v-if="getActivePenalties('team_a').length > 0" class="space-y-2">
                <div class="text-lg lg:text-2xl xl:text-3xl font-semibold text-red-300 mb-2">PENALTIES</div>
                <div 
                  v-for="penalty in getActivePenalties('team_a')" 
                  :key="penalty.playerId"
                  class="text-sm lg:text-lg xl:text-xl px-3 py-2 rounded-lg font-bold"
                  :class="{
                    'bg-yellow-500 text-black': penalty.type === 'yellow',
                    'bg-green-600 text-white': penalty.type === 'green',
                    'bg-red-600 text-white': penalty.type === 'red'
                  }"
                >
                  #{{ penalty.playerNumber }} {{ penalty.playerName }}
                </div>
              </div>
            </div>
          </div>

          <!-- Timer and Match Status -->
          <div class="text-center flex flex-col justify-center">
            <!-- Timer and Phase -->
            <div class="mb-6">
              <div class="text-2xl lg:text-4xl xl:text-6xl font-bold text-white mb-4" style="color: grey;">
                {{ currentPhaseLabel }}
              </div>
              <div class="bg-gradient-to-r from-[#1e3a8a] to-[#1e40af] text-6xl lg:text-8xl xl:text-[8rem] font-mono text-white mb-6 px-8 py-4 rounded-2xl border-2 border-blue-300 shadow-lg">
                {{ formatTime(phaseTimeLeft) }}
              </div>
            </div>

            <!-- Match Status (replaces VS) -->
            <div 
              class="px-8 py-6 rounded-3xl text-white font-bold text-2xl lg:text-4xl xl:text-6xl"
              :class="currentMatch ? getStatusColor(currentMatch.status) : 'bg-gray-500'"
            >
              {{ currentMatch ? getStatusText(currentMatch.status) : 'LOADING' }}
            </div>
          </div>

          <!-- Team B -->
          <div class="text-center flex flex-col justify-center">
            <div class="p-2">
              <!-- Selected Boosters for Team B -->
              <div v-if="!shouldHideTeamBBoosters && ((currentMatch?.boosters?.current_boosters?.teamB?.length > 0) || (currentMatch?.boosters?.teamB?.length > 0))" class="mb-1">
                <div class="flex flex-wrap justify-center gap-4 lg:gap-6">
                  <!-- Display boosters with state management -->
                  <div 
                    v-for="booster in teamBBoostersWithState" 
                    :key="booster.id || booster.name"
                    class="relative transition-all duration-300 min-w-24 lg:min-w-32"
                    :class="{
                      'opacity-60 scale-95': booster.isExpired,
                      'bg-red-600/50 rounded-2xl p-4 lg:p-6 border-3 border-red-300/70 shadow-xl backdrop-blur-sm': !booster.isExpired,
                      'bg-red-600/30 rounded-2xl p-4 lg:p-6 border-3 border-red-300/40 shadow-lg backdrop-blur-sm': booster.isExpired
                    }"
                  >
                    <div class="text-center">
                      <div class="text-4xl lg:text-5xl xl:text-6xl mb-3 drop-shadow-lg"
                           :class="{ 'opacity-50': booster.isExpired }">
                        {{ booster.icon }}
                      </div>
                      <div class="text-base lg:text-lg xl:text-xl font-bold text-white drop-shadow-md"
                           :class="{ 'opacity-50': booster.isExpired }">
                        {{ booster.name }}
                      </div>
                    </div>
                    <!-- Cross-out effect for expired boosters -->
                    <div 
                      v-if="booster.isExpired" 
                      class="absolute inset-0 flex items-center justify-center bg-black/20 rounded-2xl"
                    >
                      <div class="text-red-500 text-6xl lg:text-7xl xl:text-8xl font-bold opacity-90 transform rotate-12">✗</div>
                    </div>
                  </div>
                </div>
              </div>
              
              <h2 class="text-4xl lg:text-6xl xl:text-8xl font-bold mb-4">
                {{ teamB?.name || 'Team B' }}
              </h2>
              <div class="text-8xl lg:text-9xl xl:text-[12rem] font-black mb-4">
                {{ currentMatch?.score_b || 0 }}
              </div>
              
              <!-- Team B Penalty Corners -->
              <div class="text-yellow-300 text-2xl lg:text-4xl xl:text-6xl font-bold mb-4">
                PC: {{ currentMatch?.pc_b || 0 }}
              </div>
              
              <!-- Team B Active Penalties (simplified) -->
              <div v-if="getActivePenalties('team_b').length > 0" class="space-y-2">
                <div class="text-lg lg:text-2xl xl:text-3xl font-semibold text-red-300 mb-2">PENALTIES</div>
                <div 
                  v-for="penalty in getActivePenalties('team_b')" 
                  :key="penalty.playerId"
                  class="text-sm lg:text-lg xl:text-xl px-3 py-2 rounded-lg font-bold"
                  :class="{
                    'bg-yellow-500 text-black': penalty.type === 'yellow',
                    'bg-green-600 text-white': penalty.type === 'green',
                    'bg-red-600 text-white': penalty.type === 'red'
                  }"
                >
                  #{{ penalty.playerNumber }} {{ penalty.playerName }}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Minimal Footer -->
      <div class="text-center py-2">
        <div class="flex items-center justify-center space-x-2">
          <img 
            v-if="themeStore.currentTheme?.logo" 
            :src="themeStore.currentTheme.logo" 
            :alt="themeStore.currentTheme.name"
            class="w-4 h-4"
          />
          <span v-else class="text-sm">🏒</span>
          <p class="text-sm font-theme-text cursor-pointer hover:opacity-80 transition-opacity"
             :style="{ color: themeStore.currentTheme?.colors.textSecondary }"
             @click="toggleDebugPanel"
             :title="isDevelopment ? 'Toggle debug panel' : ''">
            Live Tournament Coverage
          </p>
        </div>
      </div>
    </div>

    <!-- Booster Countdown Overlay - Full Screen -->
    <div 
      v-if="boosterCountdown?.active"
      class="fixed inset-0 flex items-center justify-center pointer-events-none z-50"
    >
      <!-- Enhanced gradient backdrop for full screen impact -->
      <div class="absolute inset-0 bg-gradient-to-br from-black/90 to-gray-900/90 backdrop-blur-xl"></div>
      
      <!-- Main content container - Full width/height with proper spacing -->
      <div class="relative text-center w-full h-full flex flex-col justify-center px-4 py-4">
        <!-- Booster icon - Balanced size -->
        <div class="text-[8rem] lg:text-[10rem] xl:text-[12rem] mb-4 lg:mb-6 animate-pulse drop-shadow-2xl" 
             style="filter: drop-shadow(0 0 30px rgba(255,255,255,0.9)) drop-shadow(0 0 60px rgba(255,255,255,0.5))">
          {{ boosterCountdown.boosterIcon }}
        </div>
        
        <!-- Team name - Controlled size -->
        <div 
          class="text-5xl lg:text-6xl xl:text-7xl font-bold mb-4 lg:mb-6 drop-shadow-2xl"
          :class="{
            'text-blue-300': boosterCountdown.teamColor === 'blue',
            'text-red-300': boosterCountdown.teamColor === 'red'
          }"
          style="text-shadow: 4px 4px 8px rgba(0,0,0,0.9)"
        >
          {{ boosterCountdown.teamName }}
        </div>
        
        <!-- "BOOSTER INCOMING!" - Large but controlled -->
        <div class="text-4xl lg:text-6xl xl:text-7xl font-bold text-white mb-4 lg:mb-6 drop-shadow-2xl animate-pulse" 
             style="text-shadow: 4px 4px 8px rgba(0,0,0,0.9)">
          BOOSTER INCOMING!
        </div>
        
        <!-- Booster name container - Optimized -->
        <div 
          class="text-3xl lg:text-4xl xl:text-5xl font-bold px-8 py-4 lg:px-12 lg:py-6 rounded-3xl border-4 mb-4 lg:mb-6 backdrop-blur-lg shadow-2xl max-w-3xl mx-auto"
          :class="{
            'bg-blue-600/90 border-blue-200 text-blue-50': boosterCountdown.teamColor === 'blue',
            'bg-red-600/90 border-red-200 text-red-50': boosterCountdown.teamColor === 'red'
          }"
          style="box-shadow: 0 8px 32px rgba(0,0,0,0.7)"
        >
          {{ boosterCountdown.boosterName }}
        </div>
        
        <!-- Countdown number - Large but fits -->
        <div class="text-[6rem] lg:text-[8rem] xl:text-[10rem] font-bold text-yellow-300 animate-bounce drop-shadow-2xl mb-2 lg:mb-4"
             style="text-shadow: 6px 6px 12px rgba(0,0,0,0.9); filter: drop-shadow(0 0 30px rgba(255,255,0,0.8)) drop-shadow(0 0 60px rgba(255,255,0,0.5))">
          {{ boosterCountdown.countdown }}
        </div>
        
        <!-- Seconds text - Readable size -->
        <div class="text-2xl lg:text-3xl xl:text-4xl text-white drop-shadow-lg"
             style="text-shadow: 3px 3px 6px rgba(0,0,0,0.9)">
          seconds until activation
        </div>
      </div>
    </div>

    <!-- Maddie Countdown Overlay - Full Screen -->
    <div 
      v-if="maddieCountdown?.active"
      class="fixed inset-0 flex items-center justify-center pointer-events-none z-50"
    >
      <!-- Enhanced gradient backdrop for full screen impact -->
      <div class="absolute inset-0 bg-gradient-to-br from-purple-900/90 to-purple-600/90 backdrop-blur-xl"></div>
      
      <!-- Main content container - Full width/height with proper spacing -->
      <div class="relative text-center w-full h-full flex flex-col justify-center px-4 py-4">
        <!-- Maddie icon - Balanced size -->
        <div class="text-[8rem] lg:text-[10rem] xl:text-[12rem] mb-4 lg:mb-6 drop-shadow-2xl animate-pulse" 
             style="filter: drop-shadow(0 0 30px rgba(255,255,255,0.9)) drop-shadow(0 0 60px rgba(255,255,255,0.5))">
          {{ maddieCountdown.maddieIcon }}
        </div>
        
        <!-- "MADDIE INCOMING!" - Large but controlled -->
        <div class="text-4xl lg:text-6xl xl:text-7xl font-bold text-white mb-4 lg:mb-6 drop-shadow-2xl animate-pulse" 
             style="text-shadow: 4px 4px 8px rgba(0,0,0,0.9)">
          MADDIE INCOMING!
        </div>
        
        <!-- Maddie name container - Optimized -->
        <div 
          class="text-3xl lg:text-4xl xl:text-5xl font-bold px-8 py-4 lg:px-12 lg:py-6 rounded-3xl border-4 mb-4 lg:mb-6 backdrop-blur-lg bg-purple-600/90 border-purple-200 text-purple-50 shadow-2xl max-w-3xl mx-auto"
          style="box-shadow: 0 8px 32px rgba(0,0,0,0.7)"
        >
          {{ maddieCountdown.maddieName }}
        </div>
        
        <!-- Description - Compact if present -->
        <div 
          v-if="maddieCountdown.maddieDescription"
          class="text-xl lg:text-2xl xl:text-3xl text-purple-100 mb-4 lg:mb-6 drop-shadow-lg max-w-4xl mx-auto"
          style="text-shadow: 2px 2px 4px rgba(0,0,0,0.8)"
        >
          {{ maddieCountdown.maddieDescription }}
        </div>
        
        <!-- Countdown number - Large but fits -->
        <div class="text-[6rem] lg:text-[8rem] xl:text-[10rem] font-bold text-yellow-300 animate-bounce drop-shadow-2xl mb-2 lg:mb-4"
             style="text-shadow: 6px 6px 12px rgba(0,0,0,0.9); filter: drop-shadow(0 0 30px rgba(255,255,0,0.8)) drop-shadow(0 0 60px rgba(255,255,0,0.5))">
          {{ maddieCountdown.countdown }}
        </div>
        
        <!-- Seconds text - Readable size -->
        <div class="text-2xl lg:text-3xl xl:text-4xl text-white drop-shadow-lg"
             style="text-shadow: 3px 3px 6px rgba(0,0,0,0.9)">
          seconds until activation
        </div>
      </div>
    </div>

    <!-- Booster Activation Overlay -->
    <div 
      v-if="boosterActivation?.active"
      class="fixed inset-0 flex items-center justify-center pointer-events-none z-50"
    >
      <!-- Enhanced gradient backdrop -->
      <div class="absolute inset-0 bg-gradient-to-br from-black/80 to-gray-900/80 backdrop-blur-lg"></div>
      
      <!-- Main content with enhanced styling -->
      <div class="relative text-center transform animate-bounce">
        <!-- Large booster icon with enhanced glow -->
        <div class="text-[12rem] mb-8 animate-pulse drop-shadow-2xl" 
             style="filter: drop-shadow(0 0 40px rgba(255,255,255,0.9))">
          {{ boosterActivation.boosterIcon }}
        </div>
        
        <!-- Team name with enhanced contrast -->
        <div 
          class="text-6xl font-bold mb-6 drop-shadow-2xl"
          :class="{
            'text-blue-300': boosterActivation.teamColor === 'blue',
            'text-red-300': boosterActivation.teamColor === 'red'
          }"
          style="text-shadow: 4px 4px 8px rgba(0,0,0,0.9)"
        >
          {{ boosterActivation.teamName }}
        </div>
        
        <!-- "BOOSTER ACTIVATED!" text with enhanced visibility -->
        <div class="text-5xl font-bold text-white mb-6 drop-shadow-2xl"
             style="text-shadow: 4px 4px 8px rgba(0,0,0,0.9)">
          BOOSTER ACTIVATED!
        </div>
        
        <!-- Booster name with enhanced container -->
        <div 
          class="text-4xl font-bold px-12 py-6 rounded-3xl border-4 animate-pulse shadow-2xl"
          :class="{
            'bg-blue-700/90 border-blue-300 text-white': boosterActivation.teamColor === 'blue',
            'bg-red-700/90 border-red-300 text-white': boosterActivation.teamColor === 'red'
          }"
          style="text-shadow: 3px 3px 6px rgba(0,0,0,0.8); backdrop-filter: blur(8px);"
        >
          {{ boosterActivation.boosterName }}
        </div>
      </div>
    </div>

    <!-- Active Booster Timers Overlay -->
    <!--<div 
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
    -->
    <!-- Match Selector Modal -->
    <div 
      v-if="showMatchSelector"
      class="fixed inset-0 bg-black/90 backdrop-blur-sm flex items-center justify-center z-50"
    >
      <div class="bg-white/10 backdrop-blur-md rounded-2xl p-8 border border-white/20 max-w-2xl w-full mx-4">
        <div class="text-center mb-6">
          <h2 class="text-3xl font-bold text-white mb-2">{{ $t('scoreboard.selectMatch') }}</h2>
          <p class="text-blue-200">{{ $t('scoreboard.multipleMatchesFound') }}</p>
        </div>
        
        <div class="space-y-4 max-h-96 overflow-y-auto pr-2">
          <div 
            v-for="match in availableMatches" 
            :key="match.id"
            @click="selectMatch(match)"
            class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20 cursor-pointer hover:bg-white/20 transition-all duration-300"
          >
            <div class="flex items-center justify-between">
              <div class="flex-1">
                <h3 class="text-xl font-bold text-white mb-2">{{ getMatchDisplayName(match) }}</h3>
                <div class="flex items-center space-x-4 text-sm text-blue-200">
                  <span>{{ $t('scoreboard.score') }}: {{ match.score_a }} - {{ match.score_b }}</span>
                  <span>{{ $t('scoreboard.time') }}: {{ formatTime(match.time_left) }}</span>
                </div>
              </div>
              <div class="ml-4">
                <span 
                  class="px-4 py-2 rounded-full text-white font-bold text-sm"
                  :class="getStatusColor(match.status)"
                >
                  {{ getStatusText(match.status) }}
                </span>
              </div>
            </div>
          </div>
        </div>
        
        <div class="mt-6 text-center">
          <button 
            @click="showMatchSelector = false"
            class="px-6 py-3 bg-gray-600 hover:bg-gray-700 text-white rounded-lg font-medium transition-colors"
          >
            {{ $t('common.cancel') }}
          </button>
        </div>
      </div>
    </div>

    <!-- Debug Panel (only in development and when toggled) -->
    <div v-if="isDevelopment && showDebugPanel" class="fixed bottom-4 right-4 bg-black/80 text-white p-4 rounded-lg space-y-2 text-sm z-50">
      <div class="font-bold text-yellow-400">DEBUG PANEL</div>
      <div>Real-time: {{ realtimeWorking ? '✅ Working' : '❌ Failed' }}</div>
      <div>Polling: {{ pollingInterval ? '🔄 Active' : '⏸️ Inactive' }}</div>
      <div>Subscription: {{ subscriptionStatus }}</div>
      <div>Last Update: {{ lastUpdateTime }}</div>
      <div>Match ID: {{ currentMatch?.id?.slice(-8) || 'None' }}</div>
      <div class="space-x-2 pt-2">
        <button @click="testRealtimeConnection" class="bg-blue-600 px-2 py-1 rounded text-xs">Test RT</button>
        <button @click="testDatabaseUpdate" class="bg-green-600 px-2 py-1 rounded text-xs">Test DB</button>
        <button @click="startPolling" class="bg-orange-600 px-2 py-1 rounded text-xs">Start Poll</button>
        <button @click="stopPolling" class="bg-red-600 px-2 py-1 rounded text-xs">Stop Poll</button>
        <button @click="forcePollOnce" class="bg-purple-600 px-2 py-1 rounded text-xs">Poll Once</button>
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