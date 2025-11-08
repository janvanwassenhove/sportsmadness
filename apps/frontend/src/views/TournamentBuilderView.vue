<template>
  <div class="min-h-screen bg-gradient-to-br from-blue-900 via-purple-900 to-pink-900 p-4">
    <div class="container mx-auto">
      <!-- Page Header -->
      <div class="mb-8">
        <h1 class="text-4xl font-bold text-white mb-2">{{ $t('tournament.builder.title') }}</h1>
        <p class="text-blue-200">{{ $t('tournament.builder.description') }}</p>
      </div>

      <!-- Tournament Type Selection -->
      <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20 mb-8">
        <h2 class="text-2xl font-bold text-white mb-6">{{ $t('tournament.builder.chooseType') }}</h2>
        
        <div class="grid md:grid-cols-3 gap-6">
          <!-- Group Phase Only -->
          <div 
            @click="selectTournamentType('group')"
            class="tournament-type-card"
            :class="{ 'selected': selectedType === 'group' }"
          >
            <div class="tournament-type-icon">
              <div class="group-phase-diagram">
                <div class="bracket-table">
                  <div v-for="i in 4" :key="i" class="bracket-row"></div>
                </div>
              </div>
            </div>
            <h3 class="text-lg font-bold text-white mb-2">{{ $t('tournament.types.groupOnly') }}</h3>
            <p class="text-blue-200 text-sm">{{ $t('tournament.types.groupOnlyDesc') }}</p>
          </div>

          <!-- Group + Knockout -->
          <div 
            @click="selectTournamentType('mixed')"
            class="tournament-type-card"
            :class="{ 'selected': selectedType === 'mixed' }"
          >
            <div class="tournament-type-icon">
              <div class="mixed-phase-diagram">
                <div class="bracket-table small">
                  <div v-for="i in 3" :key="i" class="bracket-row"></div>
                </div>
                <div class="knockout-bracket">
                  <div class="bracket-level">
                    <div class="bracket-match"></div>
                    <div class="bracket-match"></div>
                  </div>
                  <div class="bracket-final">
                    <div class="bracket-match"></div>
                  </div>
                </div>
              </div>
            </div>
            <h3 class="text-lg font-bold text-white mb-2">{{ $t('tournament.types.mixed') }}</h3>
            <p class="text-blue-200 text-sm">{{ $t('tournament.types.mixedDesc') }}</p>
          </div>

          <!-- Knockout Only -->
          <div 
            @click="selectTournamentType('knockout')"
            class="tournament-type-card"
            :class="{ 'selected': selectedType === 'knockout' }"
          >
            <div class="tournament-type-icon">
              <div class="knockout-phase-diagram">
                <div class="knockout-bracket large">
                  <div class="bracket-level">
                    <div class="bracket-match"></div>
                    <div class="bracket-match"></div>
                  </div>
                  <div class="bracket-final">
                    <div class="bracket-match"></div>
                  </div>
                </div>
              </div>
            </div>
            <h3 class="text-lg font-bold text-white mb-2">{{ $t('tournament.types.knockoutOnly') }}</h3>
            <p class="text-blue-200 text-sm">{{ $t('tournament.types.knockoutOnlyDesc') }}</p>
          </div>
        </div>
      </div>

      <!-- Tournament Builder Section -->
      <div v-if="selectedType" class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20 mb-8">
        <div class="flex justify-between items-center mb-6">
          <h2 class="text-2xl font-bold text-white">{{ $t('tournament.builder.buildTournament') }}</h2>
          <button @click="addPhase" class="btn btn-primary">
            {{ $t('tournament.builder.addPhase') }}
          </button>
        </div>

        <p class="text-blue-200 mb-6">{{ $t('tournament.builder.buildInstructions') }}</p>

        <!-- Phase Builder -->
        <div class="space-y-6">
          <div 
            v-for="(phase, index) in phases" 
            :key="phase.id"
            class="phase-container"
          >
            <div class="flex justify-between items-center mb-4">
              <h3 class="text-xl font-bold text-white">
                {{ $t('tournament.builder.phase') }} {{ index + 1 }}
                <span v-if="phase.name" class="text-blue-200">- {{ phase.name }}</span>
              </h3>
              <div class="flex space-x-2">
                <button @click="editPhase(phase)" class="btn btn-sm btn-secondary">
                  {{ $t('common.edit') }}
                </button>
                <button 
                  @click="removePhase(index)" 
                  class="btn btn-sm bg-red-600 hover:bg-red-700 text-white"
                  v-if="phases.length > 1"
                >
                  {{ $t('common.delete') }}
                </button>
              </div>
            </div>

            <!-- Phase Type Selection -->
            <div class="grid md:grid-cols-3 gap-4 mb-4">
              <button 
                @click="setPhaseType(phase, 'poule')"
                class="phase-type-btn"
                :class="{ 'active': phase.type === 'poule' }"
              >
                + {{ $t('tournament.phaseTypes.poule') }}
              </button>
              <button 
                @click="setPhaseType(phase, 'bracket')"
                class="phase-type-btn"
                :class="{ 'active': phase.type === 'bracket' }"
              >
                + {{ $t('tournament.phaseTypes.bracket') }}
              </button>
              <button 
                @click="setPhaseType(phase, 'standalone')"
                class="phase-type-btn"
                :class="{ 'active': phase.type === 'standalone' }"
              >
                + {{ $t('tournament.phaseTypes.standalone') }}
              </button>
            </div>

            <!-- Phase Configuration -->
            <div v-if="phase.type" class="phase-config bg-white/5 rounded-lg p-4 border border-white/10">
              <!-- Poule Configuration -->
              <div v-if="phase.type === 'poule'" class="space-y-4">
                <div class="grid md:grid-cols-2 gap-4">
                  <div>
                    <label class="block text-blue-200 text-sm font-semibold mb-2">
                      {{ $t('tournament.phase.name') }}
                    </label>
                    <input 
                      v-model="phase.name"
                      type="text" 
                      class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white"
                      :placeholder="$t('tournament.phase.namePlaceholder')"
                    />
                  </div>
                  <div>
                    <label class="block text-blue-200 text-sm font-semibold mb-2">
                      {{ $t('tournament.phase.groups') }}
                    </label>
                    <input 
                      v-model.number="phase.config.groups"
                      type="number" 
                      min="1" max="10"
                      class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white"
                    />
                  </div>
                </div>
                <div class="grid md:grid-cols-2 gap-4">
                  <div>
                    <label class="block text-blue-200 text-sm font-semibold mb-2">
                      {{ $t('tournament.phase.teamsPerGroup') }}
                    </label>
                    <input 
                      v-model.number="phase.config.teamsPerGroup"
                      type="number" 
                      min="3" max="8"
                      class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white"
                    />
                  </div>
                  <div>
                    <label class="block text-blue-200 text-sm font-semibold mb-2">
                      {{ $t('tournament.phase.advancingTeams') }}
                    </label>
                    <input 
                      v-model.number="phase.config.advancingTeams"
                      type="number" 
                      min="1" max="4"
                      class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white"
                    />
                  </div>
                </div>
                
                <!-- Team Selection for Poule -->
                <div class="mt-6">
                  <label class="block text-blue-200 text-sm font-semibold mb-3">
                    {{ $t('tournament.phase.teamSelection') }}
                  </label>
                  
                  <!-- Direct team selection for first phase -->
                  <div v-if="getPhaseIndex(phase) === 0" class="space-y-3">
                    <div class="text-sm text-blue-300 mb-2">
                      {{ $t('tournament.phase.selectTeamsDirectly') }}
                    </div>
                    <div class="grid grid-cols-2 gap-2 max-h-40 overflow-y-auto bg-white/5 rounded p-3">
                      <label v-for="team in availableTeams" :key="team.id" 
                             class="flex items-center space-x-2 text-sm text-white cursor-pointer">
                        <input type="checkbox" 
                               :value="team.id"
                               v-model="phase.config.selectedTeams"
                               class="rounded border-white/20" />
                        <span>{{ team.name }}</span>
                      </label>
                    </div>
                    <div class="text-xs text-blue-300">
                      {{ $t('tournament.phase.teamsSelected') }}: {{ (phase.config.selectedTeams || []).length }}
                    </div>
                  </div>
                  
                  <!-- Team source from previous phase -->
                  <div v-else class="space-y-3">
                    <div class="text-sm text-blue-300 mb-2">
                      {{ $t('tournament.phase.teamsFromPreviousPhase') }}
                    </div>
                    <select v-model="phase.config.teamSource" 
                            class="w-full p-2 bg-white/10 border border-white/20 rounded text-white">
                      <option value="previous">{{ $t('tournament.phase.fromPreviousPhase') }}</option>
                      <option value="direct">{{ $t('tournament.phase.directSelection') }}</option>
                    </select>
                    
                    <!-- Previous phase configuration -->
                    <div v-if="phase.config.teamSource === 'previous'" class="bg-white/5 rounded p-3 space-y-2">
                      <div class="text-sm text-blue-200">{{ $t('tournament.phase.advancementRules') }}</div>
                      <div class="grid grid-cols-2 gap-2 text-sm">
                        <label class="flex items-center space-x-2 text-white">
                          <input type="radio" 
                                 value="first" 
                                 v-model="phase.config.previousPhaseConfig!.position"
                                 class="border-white/20" />
                          <span>{{ $t('tournament.phase.firstPlace') }}</span>
                        </label>
                        <label class="flex items-center space-x-2 text-white">
                          <input type="radio" 
                                 value="second" 
                                 v-model="phase.config.previousPhaseConfig!.position"
                                 class="border-white/20" />
                          <span>{{ $t('tournament.phase.secondPlace') }}</span>
                        </label>
                      </div>
                    </div>
                    
                    <!-- Direct selection for later phases -->
                    <div v-else-if="phase.config.teamSource === 'direct'" class="bg-white/5 rounded p-3">
                      <div class="grid grid-cols-2 gap-2 max-h-32 overflow-y-auto">
                        <label v-for="team in availableTeams" :key="team.id" 
                               class="flex items-center space-x-2 text-sm text-white cursor-pointer">
                          <input type="checkbox" 
                                 :value="team.id"
                                 v-model="phase.config.selectedTeams"
                                 class="rounded border-white/20" />
                          <span>{{ team.name }}</span>
                        </label>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Bracket Configuration -->
              <div v-if="phase.type === 'bracket'" class="space-y-4">
                <div class="grid md:grid-cols-2 gap-4">
                  <div>
                    <label class="block text-blue-200 text-sm font-semibold mb-2">
                      {{ $t('tournament.phase.name') }}
                    </label>
                    <input 
                      v-model="phase.name"
                      type="text" 
                      class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white"
                      :placeholder="$t('tournament.phase.namePlaceholder')"
                    />
                  </div>
                  <div>
                    <label class="block text-blue-200 text-sm font-semibold mb-2">
                      {{ $t('tournament.phase.bracketType') }}
                    </label>
                    <select 
                      v-model="phase.config.bracketType"
                      class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white"
                    >
                      <option value="single">{{ $t('tournament.bracket.single') }}</option>
                      <option value="double">{{ $t('tournament.bracket.double') }}</option>
                    </select>
                  </div>
                </div>
                <div>
                  <label class="block text-blue-200 text-sm font-semibold mb-2">
                    {{ $t('tournament.phase.participants') }}
                  </label>
                  <input 
                    v-model.number="phase.config.participants"
                    type="number" 
                    min="4" max="64"
                    step="2"
                    class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white"
                  />
                </div>
                
                <!-- Team Selection for Bracket -->
                <div class="mt-6">
                  <label class="block text-blue-200 text-sm font-semibold mb-3">
                    {{ $t('tournament.phase.teamSelection') }}
                  </label>
                  
                  <div v-if="getPhaseIndex(phase) === 0" class="space-y-3">
                    <div class="text-sm text-blue-300 mb-2">
                      {{ $t('tournament.phase.selectTeamsDirectly') }}
                    </div>
                    <div class="grid grid-cols-2 gap-2 max-h-40 overflow-y-auto bg-white/5 rounded p-3">
                      <label v-for="team in availableTeams" :key="team.id" 
                             class="flex items-center space-x-2 text-sm text-white cursor-pointer">
                        <input type="checkbox" 
                               :value="team.id"
                               v-model="phase.config.selectedTeams"
                               class="rounded border-white/20" />
                        <span>{{ team.name }}</span>
                      </label>
                    </div>
                  </div>
                  
                  <div v-else class="space-y-3">
                    <div class="text-sm text-blue-300 mb-2">
                      {{ $t('tournament.phase.teamsFromPreviousPhase') }}
                    </div>
                    <div class="bg-white/5 rounded p-3 space-y-2">
                      <div class="text-sm text-blue-200">{{ $t('tournament.phase.advancementRules') }}</div>
                      <div class="text-xs text-blue-300">
                        {{ $t('tournament.phase.bracketsUseAdvancing') }}
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Standalone Match Configuration -->
              <div v-if="phase.type === 'standalone'" class="space-y-4">
                <div class="grid md:grid-cols-2 gap-4">
                  <div>
                    <label class="block text-blue-200 text-sm font-semibold mb-2">
                      {{ $t('tournament.phase.name') }}
                    </label>
                    <input 
                      v-model="phase.name"
                      type="text" 
                      class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white"
                      :placeholder="$t('tournament.phase.namePlaceholder')"
                    />
                  </div>
                  <div>
                    <label class="block text-blue-200 text-sm font-semibold mb-2">
                      {{ $t('tournament.phase.matchType') }}
                    </label>
                    <select 
                      v-model="phase.config.matchType"
                      class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white"
                    >
                      <option value="final">{{ $t('tournament.match.final') }}</option>
                      <option value="thirdPlace">{{ $t('tournament.match.thirdPlace') }}</option>
                      <option value="friendly">{{ $t('tournament.match.friendly') }}</option>
                      <option value="custom">{{ $t('tournament.match.custom') }}</option>
                    </select>
                  </div>
                </div>
                
                <!-- Team Selection for Standalone -->
                <div class="mt-6">
                  <label class="block text-blue-200 text-sm font-semibold mb-3">
                    {{ $t('tournament.phase.teamSelection') }}
                  </label>
                  
                  <div class="space-y-3">
                    <div class="text-sm text-blue-300 mb-2">
                      {{ $t('tournament.phase.selectTwoTeams') }}
                    </div>
                    
                    <div v-if="getPhaseIndex(phase) === 0" class="bg-white/5 rounded p-3">
                      <div class="grid grid-cols-2 gap-2 max-h-32 overflow-y-auto">
                        <label v-for="team in availableTeams" :key="team.id" 
                               class="flex items-center space-x-2 text-sm text-white cursor-pointer">
                          <input type="checkbox" 
                                 :value="team.id"
                                 v-model="phase.config.selectedTeams"
                                 :disabled="(phase.config.selectedTeams || []).length >= 2 && !(phase.config.selectedTeams || []).includes(team.id)"
                                 class="rounded border-white/20" />
                          <span>{{ team.name }}</span>
                        </label>
                      </div>
                      <div class="text-xs text-blue-300 mt-2">
                        {{ $t('tournament.phase.teamsSelected') }}: {{ (phase.config.selectedTeams || []).length }}/2
                      </div>
                    </div>
                    
                    <div v-else class="bg-white/5 rounded p-3">
                      <div class="text-sm text-blue-200 mb-2">{{ $t('tournament.phase.standaloneFromPrevious') }}</div>
                      <div class="text-xs text-blue-300">
                        {{ $t('tournament.phase.standaloneExample') }}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Add Phase Buttons -->
        <div class="flex justify-center space-x-4 mt-8">
          <button @click="addPhaseType('poule')" class="btn btn-secondary">
            + {{ $t('tournament.phaseTypes.poule') }}
          </button>
          <button @click="addPhaseType('bracket')" class="btn btn-secondary">
            + {{ $t('tournament.phaseTypes.bracket') }}
          </button>
          <button @click="addPhaseType('standalone')" class="btn btn-secondary">
            + {{ $t('tournament.phaseTypes.standalone') }}
          </button>
        </div>
      </div>

      <!-- Tournament Settings -->
      <div v-if="selectedType && phases.length > 0" class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20 mb-8">
        <h2 class="text-2xl font-bold text-white mb-6">{{ $t('tournament.settings.title') }}</h2>
        
        <div class="grid md:grid-cols-2 gap-6">
          <div>
            <label class="block text-blue-200 text-sm font-semibold mb-2">
              {{ $t('tournament.settings.name') }}
            </label>
            <input 
              v-model="tournamentSettings.name"
              type="text" 
              class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white"
              :placeholder="$t('tournament.settings.namePlaceholder')"
              required
            />
          </div>
          <div>
            <label class="block text-blue-200 text-sm font-semibold mb-2">
              {{ $t('tournament.settings.startDate') }}
            </label>
            <input 
              v-model="tournamentSettings.startDate"
              type="date" 
              class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white"
              required
            />
          </div>
        </div>

        <div class="mt-6">
          <label class="block text-blue-200 text-sm font-semibold mb-2">
            {{ $t('tournament.settings.description') }}
          </label>
          <textarea 
            v-model="tournamentSettings.description"
            class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white resize-none"
            rows="3"
            :placeholder="$t('tournament.settings.descriptionPlaceholder')"
          ></textarea>
        </div>

        <!-- Match Configuration -->
        <div class="mt-6">
          <h3 class="text-lg font-bold text-white mb-4">{{ $t('tournament.settings.matchConfig') }}</h3>
          <div class="grid md:grid-cols-4 gap-4">
            <div>
              <label class="block text-blue-200 text-sm font-semibold mb-2">
                {{ tournamentSettings.quartersCount === 2 ? $t('tournament.settings.halves') : $t('tournament.settings.quarters') }}
              </label>
              <input 
                v-model.number="tournamentSettings.quartersCount"
                type="number" 
                min="1" max="4"
                class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white"
              />
            </div>
            <div>
              <label class="block text-blue-200 text-sm font-semibold mb-2">
                {{ $t('tournament.settings.quarterDuration') }}
              </label>
              <input 
                v-model.number="tournamentSettings.quarterDuration"
                type="number" 
                min="5" max="60"
                class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white"
              />
            </div>
            <div>
              <label class="block text-blue-200 text-sm font-semibold mb-2">
                {{ $t('tournament.settings.breakDuration') }}
              </label>
              <input 
                v-model.number="tournamentSettings.breakDuration"
                type="number" 
                min="1" max="10"
                class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white"
              />
            </div>
            <div v-if="tournamentSettings.quartersCount > 1">
              <label class="block text-blue-200 text-sm font-semibold mb-2">
                {{ $t('tournament.settings.halftimeDuration') }}
              </label>
              <input 
                v-model.number="tournamentSettings.halftimeDuration"
                type="number" 
                min="0" max="30"
                class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white"
              />
            </div>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="flex justify-end space-x-4 mt-8">
          <button @click="previewTournament" class="btn btn-secondary">
            {{ $t('tournament.actions.preview') }}
          </button>
          <button @click="saveTournament" class="btn btn-primary">
            {{ $t('tournament.actions.create') }}
          </button>
        </div>
      </div>

      <!-- Tournament Preview -->
      <div v-if="showPreview" class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
        <h2 class="text-2xl font-bold text-white mb-6">{{ $t('tournament.preview.title') }}</h2>
        
        <div class="space-y-4">
          <div class="bg-white/5 rounded-lg p-4">
            <h3 class="text-lg font-bold text-white mb-2">{{ tournamentSettings.name }}</h3>
            <p class="text-blue-200">{{ tournamentSettings.description }}</p>
            <div class="text-sm text-blue-300 mt-2">
              {{ $t('tournament.preview.startDate') }}: {{ formatDate(tournamentSettings.startDate) }}
            </div>
          </div>

          <div v-for="(phase, index) in phases" :key="phase.id" class="bg-white/5 rounded-lg p-4">
            <h4 class="text-md font-bold text-white mb-2">
              {{ $t('tournament.builder.phase') }} {{ index + 1 }}: {{ phase.name || $t('tournament.preview.unnamed') }}
            </h4>
            <div class="text-blue-200 text-sm">
              <div v-if="phase.type === 'poule'">
                {{ $t('tournament.preview.poule', { 
                  groups: phase.config.groups, 
                  teams: phase.config.teamsPerGroup,
                  advancing: phase.config.advancingTeams 
                }) }}
              </div>
              <div v-else-if="phase.type === 'bracket'">
                {{ $t('tournament.preview.bracket', { 
                  type: $t(`tournament.bracket.${phase.config.bracketType}`),
                  participants: phase.config.participants 
                }) }}
              </div>
              <div v-else-if="phase.type === 'standalone'">
                {{ $t('tournament.preview.standalone', { 
                  type: $t(`tournament.match.${phase.config.matchType}`) 
                }) }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import { supabase } from '../lib/supabase'

const { t } = useI18n()
const router = useRouter()

// Tournament type selection
const selectedType = ref<'group' | 'mixed' | 'knockout' | null>(null)
const showPreview = ref(false)

// Team management
interface Team {
  id: string
  name: string
  players: any[]
}

const availableTeams = ref<Team[]>([])
const loadingTeams = ref(false)

// Phase management
interface PhaseConfig {
  groups?: number
  teamsPerGroup?: number
  advancingTeams?: number
  bracketType?: 'single' | 'double'
  participants?: number
  matchType?: 'final' | 'thirdPlace' | 'friendly' | 'custom'
  selectedTeams?: string[] // Team IDs selected for this phase
  teamSource?: 'direct' | 'previous' // Direct selection or from previous phase
  previousPhaseConfig?: {
    phaseId: string
    position: 'first' | 'second' | 'third' | 'specific'
    fromGroup?: string
  }
}

interface Phase {
  id: string
  name: string
  type: 'poule' | 'bracket' | 'standalone' | null
  config: PhaseConfig
  order: number
}

const phases = ref<Phase[]>([])

// Tournament settings
const tournamentSettings = reactive({
  name: '',
  description: '',
  startDate: '',
  quartersCount: 4,
  quarterDuration: 15,
  breakDuration: 2,
  halftimeDuration: 10,
  tournamentStartTime: '09:00',
  matchGap: 15
})

// Load teams on component mount
onMounted(async () => {
  await loadTeams()
})

async function loadTeams() {
  try {
    loadingTeams.value = true
    const { data, error } = await supabase
      .from('teams')
      .select('id, name, players')
      .order('name')
    
    if (error) throw error
    availableTeams.value = data || []
  } catch (error) {
    console.error('Error loading teams:', error)
  } finally {
    loadingTeams.value = false
  }
}

// Methods
function selectTournamentType(type: 'group' | 'mixed' | 'knockout') {
  selectedType.value = type
  phases.value = []
  
  // Initialize with default phases based on type
  if (type === 'group') {
    addPhaseType('poule')
  } else if (type === 'mixed') {
    addPhaseType('poule')
    addPhaseType('bracket')
  } else if (type === 'knockout') {
    addPhaseType('bracket')
  }
}

function addPhase() {
  const newPhase: Phase = {
    id: `phase_${Date.now()}`,
    name: '',
    type: null,
    config: {},
    order: phases.value.length
  }
  phases.value.push(newPhase)
}

function addPhaseType(type: 'poule' | 'bracket' | 'standalone') {
  const newPhase: Phase = {
    id: `phase_${Date.now()}`,
    name: getDefaultPhaseName(type),
    type,
    config: getDefaultPhaseConfig(type),
    order: phases.value.length
  }
  phases.value.push(newPhase)
}

function getDefaultPhaseName(type: string): string {
  switch (type) {
    case 'poule': return t('tournament.phaseTypes.poule')
    case 'bracket': return t('tournament.phaseTypes.bracket')
    case 'standalone': return t('tournament.phaseTypes.standalone')
    default: return ''
  }
}

function getDefaultPhaseConfig(type: string): PhaseConfig {
  switch (type) {
    case 'poule':
      return {
        groups: 2,
        teamsPerGroup: 4,
        advancingTeams: 2,
        selectedTeams: [],
        teamSource: 'direct',
        previousPhaseConfig: {
          phaseId: '',
          position: 'first',
          fromGroup: ''
        }
      }
    case 'bracket':
      return {
        bracketType: 'single',
        participants: 8,
        selectedTeams: [],
        teamSource: 'direct',
        previousPhaseConfig: {
          phaseId: '',
          position: 'first',
          fromGroup: ''
        }
      }
    case 'standalone':
      return {
        matchType: 'final',
        selectedTeams: [],
        teamSource: 'direct'
      }
    default:
      return {}
  }
}

function getPhaseIndex(phase: Phase): number {
  return phases.value.findIndex(p => p.id === phase.id)
}

function setPhaseType(phase: Phase, type: 'poule' | 'bracket' | 'standalone') {
  phase.type = type
  phase.name = getDefaultPhaseName(type)
  phase.config = getDefaultPhaseConfig(type)
}

function removePhase(index: number) {
  if (phases.value.length > 1) {
    phases.value.splice(index, 1)
  }
}

function editPhase(phase: Phase) {
  // Phase editing handled inline
}

function previewTournament() {
  showPreview.value = !showPreview.value
}

async function saveTournament() {
  try {
    if (!tournamentSettings.name || !tournamentSettings.startDate) {
      alert(t('tournament.validation.required'))
      return
    }

    if (phases.value.length === 0) {
      alert(t('tournament.validation.phases'))
      return
    }

    // Validate all phases have required data
    for (const phase of phases.value) {
      if (!phase.type) {
        alert(t('tournament.validation.phaseType'))
        return
      }
    }

    // Create tournament structure
    const tournamentData = {
      name: tournamentSettings.name,
      description: tournamentSettings.description,
      start_date: tournamentSettings.startDate,
      end_date: tournamentSettings.startDate, // Can be updated later
      status: 'setup',
      quarters_count: tournamentSettings.quartersCount,
      quarter_duration_minutes: tournamentSettings.quarterDuration,
      break_duration_minutes: tournamentSettings.breakDuration,
      halftime_duration_minutes: tournamentSettings.halftimeDuration,
      tournament_start_time: tournamentSettings.tournamentStartTime + ':00',
      match_gap_minutes: tournamentSettings.matchGap,
      tournament_type: selectedType.value,
      phases: phases.value
    }

    // Save to database
    const { data: tournament, error } = await supabase
      .from('tournaments')
      .insert([tournamentData])
      .select()
      .single()

    if (error) {
      console.error('Error creating tournament:', error)
      alert(t('tournament.errors.create'))
      return
    }

    // Create divisions for each phase
    for (const phase of phases.value) {
      const divisionData = {
        tournament_id: tournament.id,
        name: phase.name,
        type: phase.type === 'poule' ? 'group' : phase.type === 'bracket' ? 'knockout' : 'standalone',
        phase_order: phase.order,
        phase_config: phase.config
      }

      const { error: divisionError } = await supabase
        .from('divisions')
        .insert([divisionData])

      if (divisionError) {
        console.error('Error creating division:', divisionError)
      }
    }

    alert(t('tournament.success.created'))
    router.push('/admin/tournaments')

  } catch (error) {
    console.error('Error:', error)
    alert(t('tournament.errors.unexpected'))
  }
}

function formatDate(dateString: string): string {
  if (!dateString) return ''
  return new Date(dateString).toLocaleDateString()
}
</script>

<style scoped>
.tournament-type-card {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 0.5rem;
  padding: 1.5rem;
  cursor: pointer;
  transition: all 0.2s ease;
}

.tournament-type-card:hover {
  border-color: rgba(255, 255, 255, 0.4);
  background: rgba(255, 255, 255, 0.1);
}

.tournament-type-card.selected {
  border-color: #60a5fa;
  background: rgba(96, 165, 250, 0.2);
}

.tournament-type-icon {
  margin-bottom: 1rem;
  display: flex;
  justify-content: center;
}

.group-phase-diagram .bracket-table {
  width: 4rem;
  height: 3rem;
  border: 1px solid rgba(255, 255, 255, 0.4);
  border-radius: 0.25rem;
}

.bracket-table .bracket-row {
  height: 0.5rem;
  border-bottom: 1px solid rgba(255, 255, 255, 0.2);
}

.bracket-table .bracket-row:last-child {
  border-bottom: none;
}

.bracket-table.small {
  width: 3rem;
  height: 2rem;
}

.mixed-phase-diagram {
  display: flex;
  gap: 0.5rem;
  align-items: center;
}

.knockout-bracket {
  display: flex;
  gap: 0.25rem;
}

.knockout-bracket.large {
  transform: scale(1.25);
}

.bracket-level {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.bracket-match {
  width: 1rem;
  height: 0.5rem;
  border: 1px solid rgba(255, 255, 255, 0.4);
  border-radius: 0.125rem;
}

.bracket-final .bracket-match {
  width: 1rem;
  height: 1rem;
}

.phase-container {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 0.5rem;
  padding: 1.5rem;
}

.phase-type-btn {
  padding: 0.5rem 1rem;
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 0.5rem;
  color: white;
  background: transparent;
  transition: all 0.2s ease;
  cursor: pointer;
}

.phase-type-btn:hover {
  border-color: rgba(255, 255, 255, 0.4);
  background: rgba(255, 255, 255, 0.1);
}

.phase-type-btn.active {
  border-color: #60a5fa;
  background: rgba(96, 165, 250, 0.2);
  color: #dbeafe;
}

.phase-config {
  margin-top: 1rem;
}
</style>