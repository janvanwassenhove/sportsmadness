// Timeline event types and interfaces for match statistics

export type TimelineEventType = 
  | 'goal'
  | 'booster_activated'
  | 'maddie_activated'
  | 'card_issued'
  | 'match_started'
  | 'match_paused'
  | 'match_resumed'
  | 'match_finished'
  | 'penalty_corner'

export type CardType = 'yellow' | 'green' | 'red'

export interface BaseTimelineEvent {
  type: TimelineEventType
  timestamp: string // ISO 8601 format
  team?: 'a' | 'b' | null // null for match-wide events
  matchTime?: number // Time left when event occurred (in seconds)
}

export interface GoalEvent extends BaseTimelineEvent {
  type: 'goal'
  team: 'a' | 'b'
  details: {
    score_a: number
    score_b: number
    pc: boolean // Was it from a penalty corner?
  }
}

export interface PenaltyCornerEvent extends BaseTimelineEvent {
  type: 'penalty_corner'
  team: 'a' | 'b'
  details: {
    pc_a: number
    pc_b: number
  }
}

export interface BoosterActivatedEvent extends BaseTimelineEvent {
  type: 'booster_activated'
  team: 'a' | 'b'
  details: {
    booster_id: string
    booster_name: string
    booster_icon: string
    duration?: number // in minutes
  }
}

export interface MaddieActivatedEvent extends BaseTimelineEvent {
  type: 'maddie_activated'
  team: null
  details: {
    maddie_id: string
    maddie_name: string
    maddie_icon: string
    duration?: number // in minutes
  }
}

export interface CardIssuedEvent extends BaseTimelineEvent {
  type: 'card_issued'
  team: 'a' | 'b'
  details: {
    card_type: CardType
    player_name: string
    player_number: string | number
    duration: number | 'never' // in seconds, or 'never' for red cards
  }
}

export interface MatchStatusEvent extends BaseTimelineEvent {
  type: 'match_started' | 'match_paused' | 'match_resumed' | 'match_finished'
  team: null
  details: {
    status: string
  }
}

export type TimelineEvent = 
  | GoalEvent 
  | BoosterActivatedEvent 
  | MaddieActivatedEvent 
  | CardIssuedEvent 
  | MatchStatusEvent
  | PenaltyCornerEvent

// Helper function to create timeline events
export function createTimelineEvent<T extends TimelineEvent>(
  type: TimelineEventType,
  team: 'a' | 'b' | null,
  details: T['details'],
  matchTime?: number
): T {
  return {
    type,
    timestamp: new Date().toISOString(),
    team,
    matchTime,
    details
  } as T
}

// Helper to add event to match timeline
export function addTimelineEvent(
  currentTimeline: TimelineEvent[],
  newEvent: TimelineEvent
): TimelineEvent[] {
  return [...currentTimeline, newEvent]
}

// Helper to get events by type
export function getEventsByType(
  timeline: TimelineEvent[],
  type: TimelineEventType
): TimelineEvent[] {
  return timeline.filter(event => event.type === type)
}

// Helper to get events by team
export function getEventsByTeam(
  timeline: TimelineEvent[],
  team: 'a' | 'b'
): TimelineEvent[] {
  return timeline.filter(event => event.team === team)
}

// Helper to format timeline event for display
export function formatTimelineEvent(event: TimelineEvent, teamAName: string, teamBName: string): string {
  const teamName = event.team === 'a' ? teamAName : event.team === 'b' ? teamBName : 'Match'
  const time = event.matchTime ? formatMatchTime(event.matchTime) : '00:00'
  
  switch (event.type) {
    case 'goal':
      const goalEvent = event as GoalEvent
      return `${time} - ${teamName} scored! (${goalEvent.details.score_a}-${goalEvent.details.score_b})${goalEvent.details.pc ? ' [PC]' : ''}`
    
    case 'penalty_corner':
      const pcEvent = event as PenaltyCornerEvent
      return `${time} - ${teamName} penalty corner (${pcEvent.details.pc_a}-${pcEvent.details.pc_b})`
    
    case 'booster_activated':
      const boosterEvent = event as BoosterActivatedEvent
      return `${time} - ${teamName} activated ${boosterEvent.details.booster_icon} ${boosterEvent.details.booster_name}`
    
    case 'maddie_activated':
      const maddieEvent = event as MaddieActivatedEvent
      return `${time} - Maddie activated: ${maddieEvent.details.maddie_icon} ${maddieEvent.details.maddie_name}`
    
    case 'card_issued':
      const cardEvent = event as CardIssuedEvent
      const cardEmoji = cardEvent.details.card_type === 'yellow' ? '🟨' : cardEvent.details.card_type === 'green' ? '🟩' : '🟥'
      return `${time} - ${teamName}: ${cardEmoji} ${cardEvent.details.card_type.toUpperCase()} card for ${cardEvent.details.player_name} (#${cardEvent.details.player_number})`
    
    case 'match_started':
      return `${time} - Match started`
    
    case 'match_paused':
      return `${time} - Match paused`
    
    case 'match_resumed':
      return `${time} - Match resumed`
    
    case 'match_finished':
      return `${time} - Match finished`
    
    default:
      return `${time} - Unknown event`
  }
}

function formatMatchTime(seconds: number): string {
  const mins = Math.floor(seconds / 60)
  const secs = seconds % 60
  return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
}
