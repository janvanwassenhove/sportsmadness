<template>
  <div class="min-h-screen bg-gradient-to-br from-blue-900 via-purple-900 to-pink-900 p-4">
    <div class="container mx-auto">
      <!-- Page Header -->
      <div class="mb-8">
        <h1 class="text-4xl font-bold text-white mb-2">Tournament Management</h1>
        <p class="text-blue-200">Create and manage tournaments with group and knockout phases</p>
      </div>

      <!-- Tournament Selection/Creation -->
      <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20 mb-8">
        <div class="flex justify-between items-center mb-6">
          <h2 class="text-2xl font-bold text-white">Tournaments</h2>
          <div class="flex space-x-3">
            <RouterLink 
              to="/admin/tournaments/builder"
              class="btn btn-secondary"
            >
              🏗️ Tournament Builder
            </RouterLink>
            <button 
              @click="showCreateTournament = true" 
              class="btn btn-primary"
            >
              Create Tournament
            </button>
          </div>
        </div>

        <!-- Tournament List -->
        <div v-if="tournaments.length > 0" class="grid md:grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
          <div 
            v-for="tournament in tournaments" 
            :key="tournament.id"
            class="bg-white/5 rounded-lg p-4 border border-white/10 hover:border-white/30 transition-colors relative"
            :class="{ 'border-yellow-400 bg-yellow-400/10': selectedTournament?.id === tournament.id }"
          >
            <div @click="selectTournament(tournament)" class="cursor-pointer">
              <h3 class="text-lg font-bold text-white mb-2">{{ tournament.name }}</h3>
              <div class="text-sm text-blue-200 space-y-1">
                <div>{{ formatDate(tournament.start_date) }}</div>
                <div v-if="tournament.end_date">- {{ formatDate(tournament.end_date) }}</div>
                <div class="capitalize">
                  <span class="inline-block px-2 py-1 rounded text-xs" 
                        :class="getStatusClass(tournament.status)">
                    {{ tournament.status }}
                  </span>
                </div>
              </div>
            </div>
            
            <!-- Delete Button -->
            <button 
              @click.stop="deleteTournament(tournament.id)"
              class="absolute top-2 right-2 btn btn-xs bg-red-600 hover:bg-red-700 text-white opacity-0 hover:opacity-100 transition-opacity"
              title="Delete Tournament"
              :class="{ 'opacity-100': selectedTournament?.id === tournament.id }"
            >
              🗑️
            </button>
          </div>
        </div>

        <div v-else class="text-center py-8">
          <div class="text-white/60 mb-4">No tournaments created yet</div>
          <button @click="showCreateTournament = true" class="btn btn-primary">
            Create Your First Tournament
          </button>
        </div>
      </div>

      <!-- Tournament Management (when tournament is selected) -->
      <div v-if="selectedTournament" class="space-y-8">
        <!-- Tournament Info -->
        <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
          <div class="flex justify-between items-center mb-4">
            <h2 class="text-2xl font-bold text-white">{{ selectedTournament.name }}</h2>
            <div class="flex space-x-2">
              <button 
                @click="openEditTournament()" 
                class="btn btn-secondary"
              >
                Edit Info
              </button>
              <button 
                v-if="selectedTournament.status === 'setup'"
                @click="startTournament" 
                class="btn btn-success"
              >
                Start Tournament
              </button>
              <button 
                @click="deleteTournament(selectedTournament.id)"
                class="btn bg-red-600 hover:bg-red-700 text-white"
                title="Delete Tournament"
              >
                🗑️ Delete
              </button>
            </div>
          </div>
          
          <div class="grid md:grid-cols-3 gap-4 text-sm">
            <div>
              <span class="text-blue-200">Start Date:</span>
              <div class="text-white font-semibold">{{ formatDate(selectedTournament.start_date) }}</div>
            </div>
            <div v-if="selectedTournament.end_date">
              <span class="text-blue-200">End Date:</span>
              <div class="text-white font-semibold">{{ formatDate(selectedTournament.end_date) }}</div>
            </div>
            <div>
              <span class="text-blue-200">Status:</span>
              <div class="capitalize">
                <span class="inline-block px-2 py-1 rounded text-xs font-semibold" 
                      :class="getStatusClass(selectedTournament.status)">
                  {{ selectedTournament.status }}
                </span>
              </div>
            </div>
          </div>
          
          <div v-if="selectedTournament.description" class="mt-4">
            <span class="text-blue-200">Description:</span>
            <p class="text-white mt-1">{{ selectedTournament.description }}</p>
          </div>
          
          <!-- Match Duration Settings -->
          <div class="mt-4 p-4 bg-white/5 rounded-lg border border-white/10">
            <h4 class="text-blue-200 font-semibold mb-3">Match Configuration</h4>
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm mb-4">
              <div>
                <span class="text-blue-200">Quarters:</span>
                <div class="text-white font-semibold">{{ selectedTournament.quarters_count || 4 }}</div>
              </div>
              <div>
                <span class="text-blue-200">Quarter Length:</span>
                <div class="text-white font-semibold">{{ selectedTournament.quarter_duration_minutes || 15 }}min</div>
              </div>
              <div>
                <span class="text-blue-200">Break Time:</span>
                <div class="text-white font-semibold">{{ selectedTournament.break_duration_minutes || 2 }}min</div>
              </div>
              <div>
                <span class="text-blue-200">Halftime:</span>
                <div class="text-white font-semibold">{{ selectedTournament.halftime_duration_minutes || 10 }}min</div>
              </div>
            </div>
            
            <!-- Scheduling Information -->
            <div class="grid grid-cols-2 md:grid-cols-3 gap-4 text-sm border-t border-white/10 pt-3">
              <div>
                <span class="text-blue-200">Start Time:</span>
                <div class="text-white font-semibold">{{ formatTime(selectedTournament.tournament_start_time) || '09:00' }}</div>
              </div>
              <div>
                <span class="text-blue-200">Match Gap:</span>
                <div class="text-white font-semibold">{{ selectedTournament.match_gap_minutes || 15 }}min</div>
              </div>
              <div>
                <span class="text-blue-200">Match Slot:</span>
                <div class="text-white font-semibold">{{ calculateSelectedTournamentMatchTime() + (selectedTournament.match_gap_minutes || 15) }}min</div>
              </div>
            </div>
            
            <div class="text-xs text-white/60 mt-2">
              Match duration: {{ calculateSelectedTournamentMatchTime() }}min + {{ selectedTournament.match_gap_minutes || 15 }}min gap = {{ calculateSelectedTournamentMatchTime() + (selectedTournament.match_gap_minutes || 15) }}min per slot
            </div>
            
            <!-- Tournament Schedule Overview -->
            <div class="mt-3 p-3 bg-white/5 rounded border border-white/5">
              <div class="flex justify-between items-center mb-2">
                <div class="text-xs text-blue-200">Tournament Schedule Overview:</div>
                <div class="text-xs text-white/60">{{ getTotalTournamentMatches() }} total matches</div>
              </div>
              
              <div class="space-y-2">
                <!-- Division-wise match schedule preview -->
                <div v-for="division in divisions.slice(0, 2)" :key="division.id" class="text-xs">
                  <div class="text-white/80 font-semibold mb-1">{{ division.name }}:</div>
                  <div class="grid grid-cols-2 gap-2 ml-2">
                    <div v-for="(match, index) in getDivisionMatches(division).slice(0, 2)" :key="match.id" class="text-white/60">
                      {{ formatTime(calculateDivisionMatchStartTime(division, index)) }} - {{ getTeamName(match.team_a) }} vs {{ getTeamName(match.team_b) }}
                    </div>
                    <div v-if="getDivisionMatches(division).length === 0" class="text-white/40 col-span-2">
                      No matches scheduled
                    </div>
                  </div>
                </div>
                
                <div v-if="divisions.length > 2" class="text-xs text-white/40 text-center pt-1">
                  +{{ divisions.length - 2 }} more divisions...
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Divisions Management -->
        <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20">
          <div class="flex justify-between items-center mb-6">
            <h3 class="text-xl font-bold text-white">Tournament Structure</h3>
            <button 
              @click="showCreateDivision = true" 
              class="btn btn-primary"
              :disabled="selectedTournament.status !== 'setup'"
            >
              Add Division
            </button>
          </div>

          <!-- Division List -->
          <div v-if="divisions.length > 0" class="space-y-4">
            <div 
              v-for="(division, index) in divisions" 
              :key="division.id"
              class="bg-white/5 rounded-lg p-4 border border-white/10"
            >
              <div class="flex justify-between items-center mb-4">
                <div class="flex items-center space-x-4">
                  <h4 class="text-lg font-bold text-white">
                    {{ index + 1 }}. {{ division.name }}
                  </h4>
                  <span class="px-2 py-1 rounded text-xs font-semibold"
                        :class="division.type === 'group' ? 'bg-green-500/20 text-green-300' : 'bg-red-500/20 text-red-300'">
                    {{ division.type === 'group' ? 'Group Phase' : 'Knockout Phase' }}
                  </span>
                </div>
                <div class="flex space-x-2">
                  <button 
                    @click="manageDivision(division)" 
                    class="btn btn-sm btn-secondary"
                  >
                    Manage
                  </button>
                  <button 
                    v-if="selectedTournament.status === 'setup'"
                    @click="deleteDivision(division.id)" 
                    class="btn btn-sm btn-danger"
                  >
                    Delete
                  </button>
                </div>
              </div>

              <!-- Groups (for group divisions) -->
              <div v-if="division.type === 'group' && divisionGroups[division.id] && divisionGroups[division.id]!.length > 0" class="space-y-2">
                <h5 class="text-white font-semibold">Groups:</h5>
                <div class="grid grid-cols-2 md:grid-cols-4 gap-2">
                  <div 
                    v-for="group in divisionGroups[division.id]" 
                    :key="group.id"
                    class="bg-white/5 rounded p-2 text-center"
                  >
                    <div class="text-white font-semibold">{{ group.name }}</div>
                    <div class="text-xs text-blue-200">
                      {{ getGroupTeamCount(group.id) }} teams
                    </div>
                  </div>
                </div>
              </div>

              <!-- Team Count for Knockout -->
              <div v-if="division.type === 'knockout'" class="text-sm text-blue-200">
                {{ getDivisionTeamCount(division.id) }} teams registered
              </div>

              <!-- Matches Section -->
              <div class="mt-4 border-t border-white/10 pt-3">
                <div class="flex justify-between items-center mb-3">
                  <h5 class="text-white font-semibold">Scheduled Matches</h5>
                  <div class="flex space-x-2">
                    <button 
                      v-if="selectedTournament.status === 'setup'"
                      @click="generateDivisionSchedule(division)" 
                      class="btn btn-xs btn-primary"
                    >
                      Generate Schedule
                    </button>
                    <button 
                      v-if="hasPlaceholderTeams(division)"
                      @click="resolvePlaceholderTeams(division.id)" 
                      class="btn btn-xs btn-accent"
                    >
                      Update Teams
                    </button>
                    <button 
                      @click="showDivisionMatches(division)" 
                      class="btn btn-xs btn-secondary"
                    >
                      View All Matches
                    </button>
                  </div>
                </div>
                
                <!-- Sample matches preview (first 3) -->
                <div v-if="getDivisionMatchCount(division) > 0" class="space-y-2">
                  <div 
                    v-for="(match, matchIndex) in getDivisionMatches(division).slice(0, 3)" 
                    :key="match.id"
                    class="bg-white/5 rounded p-3 text-sm"
                  >
                    <div class="flex justify-between items-center">
                      <div class="flex items-center space-x-4">
                        <div class="text-blue-200 font-mono">
                          {{ formatTime(calculateDivisionMatchStartTime(division, matchIndex)) }}
                        </div>
                        <div class="text-white">
                          {{ getTeamName(match.team_a) }} vs {{ getTeamName(match.team_b) }}
                        </div>
                      </div>
                      <div class="flex items-center space-x-2">
                        <div class="text-xs text-white/60">
                          {{ match.status || 'Scheduled' }}
                        </div>
                        <button 
                          v-if="selectedTournament.status === 'setup'"
                          @click="editMatch(match)" 
                          class="btn btn-xs bg-blue-600 hover:bg-blue-700 text-white"
                          title="Edit Match Settings"
                        >
                          ⚙️
                        </button>
                        <button 
                          v-if="selectedTournament.status === 'setup'"
                          @click="deleteMatch(match.id)" 
                          class="btn btn-xs bg-red-600 hover:bg-red-700 text-white"
                          title="Delete Match"
                        >
                          🗑️
                        </button>
                      </div>
                    </div>
                  </div>
                  
                  <div v-if="getDivisionMatchCount(division) > 3" class="text-xs text-blue-200 text-center py-2">
                    +{{ getDivisionMatchCount(division) - 3 }} more matches...
                  </div>
                </div>
                
                <div v-else class="text-xs text-white/60 text-center py-3">
                  No matches scheduled yet
                </div>
              </div>
            </div>
          </div>

          <div v-else class="text-center py-8">
            <div class="text-white/60 mb-4">No divisions created yet</div>
            <div class="text-sm text-blue-200">
              Add group phases for round-robin matches or knockout phases for elimination rounds
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Create Tournament Modal -->
    <div v-if="showCreateTournament" class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50">
      <div class="bg-gray-900 rounded-xl p-6 border border-white/20 max-w-md w-full mx-4">
        <h3 class="text-xl font-bold text-white mb-4">Create Tournament</h3>
        
        <form @submit.prevent="createTournament" class="space-y-4">
          <div>
            <label class="block text-blue-200 text-sm font-semibold mb-2">Tournament Name</label>
            <input 
              v-model="newTournament.name"
              type="text" 
              class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-white/50"
              placeholder="Enter tournament name"
              required
            />
          </div>

          <div>
            <label class="block text-blue-200 text-sm font-semibold mb-2">Start Date</label>
            <input 
              v-model="newTournament.start_date"
              type="date" 
              class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white"
              required
            />
          </div>

          <div>
            <label class="block text-blue-200 text-sm font-semibold mb-2">End Date (Optional)</label>
            <input 
              v-model="newTournament.end_date"
              type="date" 
              class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white"
            />
          </div>

          <div>
            <label class="block text-blue-200 text-sm font-semibold mb-2">Description (Optional)</label>
            <textarea 
              v-model="newTournament.description"
              class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-white/50 resize-none"
              rows="3"
              placeholder="Enter tournament description"
            ></textarea>
          </div>

          <!-- Match Duration Configuration -->
          <div class="border border-white/20 rounded-lg p-4">
            <h4 class="text-blue-200 font-semibold mb-3">Match Duration Settings</h4>
            
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block text-blue-200 text-xs font-semibold mb-1">
                  {{ newTournament.quarters_count === 2 ? 'Halves' : 'Quarters' }}
                </label>
                <input 
                  v-model.number="newTournament.quarters_count"
                  type="number" 
                  min="1" 
                  max="6"
                  class="w-full p-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                />
              </div>
              
              <div>
                <label class="block text-blue-200 text-xs font-semibold mb-1">
                  {{ newTournament.quarters_count === 2 ? 'Half Duration (min)' : 'Quarter Duration (min)' }}
                </label>
                <input 
                  v-model.number="newTournament.quarter_duration_minutes"
                  type="number" 
                  min="5" 
                  max="30"
                  class="w-full p-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                />
              </div>
              
              <div v-if="newTournament.quarters_count > 2">
                <label class="block text-blue-200 text-xs font-semibold mb-1">Break Duration (min)</label>
                <input 
                  v-model.number="newTournament.break_duration_minutes"
                  type="number" 
                  min="1" 
                  max="10"
                  class="w-full p-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                />
              </div>
              
              <div v-if="newTournament.quarters_count > 1">
                <label class="block text-blue-200 text-xs font-semibold mb-1">
                  {{ newTournament.quarters_count === 2 ? 'Halftime (min)' : 'Halftime (min)' }}
                </label>
                <input 
                  v-model.number="newTournament.halftime_duration_minutes"
                  type="number" 
                  min="0" 
                  max="20"
                  class="w-full p-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                />
              </div>
            </div>
            
            <div class="text-xs text-white/60 mt-2">
              Total match time: {{ calculateTotalMatchTime() }} minutes
            </div>
          </div>

          <!-- Match Scheduling Configuration -->
          <div class="border border-white/20 rounded-lg p-4">
            <h4 class="text-blue-200 font-semibold mb-3">Match Scheduling</h4>
            
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block text-blue-200 text-xs font-semibold mb-1">Tournament Start Time</label>
                <input 
                  v-model="newTournament.tournament_start_time"
                  type="time" 
                  class="w-full p-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                />
              </div>
              
              <div>
                <label class="block text-blue-200 text-xs font-semibold mb-1">Gap Between Matches (min)</label>
                <input 
                  v-model.number="newTournament.match_gap_minutes"
                  type="number" 
                  min="5" 
                  max="60"
                  class="w-full p-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                />
              </div>
            </div>
            
            <div class="text-xs text-white/60 mt-2">
              Match window: {{ calculateTotalMatchTime() + newTournament.match_gap_minutes }} minutes per match slot
            </div>
          </div>

          <div class="flex space-x-3 pt-4">
            <button type="submit" class="flex-1 btn btn-primary">
              Create Tournament
            </button>
            <button 
              type="button" 
              @click="showCreateTournament = false; resetNewTournament()"
              class="flex-1 btn btn-secondary"
            >
              Cancel
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Create Division Modal -->
    <div v-if="showCreateDivision" class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50">
      <div class="bg-gray-900 rounded-xl p-6 border border-white/20 max-w-md w-full mx-4">
        <h3 class="text-xl font-bold text-white mb-4">Add Division</h3>
        
        <form @submit.prevent="createDivision" class="space-y-4">
          <div>
            <label class="block text-blue-200 text-sm font-semibold mb-2">Division Name</label>
            <input 
              v-model="newDivision.name"
              type="text" 
              class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-white/50"
              placeholder="e.g. Group Stage, Quarter Finals"
              required
            />
          </div>

          <div>
            <label class="block text-blue-200 text-sm font-semibold mb-2">Division Type</label>
            <select 
              v-model="newDivision.type"
              class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white"
              required
            >
              <option value="">Select type</option>
              <option value="group">Group Phase (Round Robin)</option>
              <option value="knockout">Knockout Phase (Elimination)</option>
            </select>
          </div>

          <!-- Group-specific settings -->
          <div v-if="newDivision.type === 'group'" class="space-y-3">
            <div>
              <label class="block text-blue-200 text-sm font-semibold mb-2">Number of Groups</label>
              <input 
                v-model.number="newDivision.numGroups"
                type="number" 
                min="1" 
                max="8"
                class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white"
                placeholder="How many groups?"
              />
            </div>
            <div>
              <label class="block text-blue-200 text-sm font-semibold mb-2">Teams per Group</label>
              <input 
                v-model.number="newDivision.teamsPerGroup"
                type="number" 
                min="2" 
                max="8"
                class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white"
                placeholder="How many teams per group?"
              />
            </div>
          </div>

          <div class="flex space-x-3 pt-4">
            <button type="submit" class="flex-1 btn btn-primary">
              Add Division
            </button>
            <button 
              type="button" 
              @click="showCreateDivision = false; resetNewDivision()"
              class="flex-1 btn btn-secondary"
            >
              Cancel
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Edit Tournament Modal -->
    <div v-if="editingTournament" class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50">
      <div class="bg-gray-900 rounded-xl p-6 border border-white/20 max-w-md w-full mx-4">
        <h3 class="text-xl font-bold text-white mb-4">Edit Tournament</h3>
        
        <form @submit.prevent="updateTournament" class="space-y-4">
          <div>
            <label class="block text-blue-200 text-sm font-semibold mb-2">Tournament Name</label>
            <input 
              v-model="editTournament.name"
              type="text" 
              class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white"
              required
            />
          </div>

          <div>
            <label class="block text-blue-200 text-sm font-semibold mb-2">Start Date</label>
            <input 
              v-model="editTournament.start_date"
              type="date" 
              class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white"
              required
            />
          </div>

          <div>
            <label class="block text-blue-200 text-sm font-semibold mb-2">End Date (Optional)</label>
            <input 
              v-model="editTournament.end_date"
              type="date" 
              class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white"
            />
          </div>

          <div>
            <label class="block text-blue-200 text-sm font-semibold mb-2">Description (Optional)</label>
            <textarea 
              v-model="editTournament.description"
              class="w-full p-3 bg-white/10 border border-white/20 rounded-lg text-white resize-none"
              rows="3"
            ></textarea>
          </div>

          <!-- Match Duration Configuration -->
          <div class="border border-white/20 rounded-lg p-4">
            <h4 class="text-blue-200 font-semibold mb-3">Match Duration Settings</h4>
            
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block text-blue-200 text-xs font-semibold mb-1">
                  {{ editTournament.quarters_count === 2 ? 'Halves' : 'Quarters' }}
                </label>
                <input 
                  v-model.number="editTournament.quarters_count"
                  type="number" 
                  min="1" 
                  max="6"
                  class="w-full p-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                />
              </div>
              
              <div>
                <label class="block text-blue-200 text-xs font-semibold mb-1">
                  {{ editTournament.quarters_count === 2 ? 'Half Duration (min)' : 'Quarter Duration (min)' }}
                </label>
                <input 
                  v-model.number="editTournament.quarter_duration_minutes"
                  type="number" 
                  min="5" 
                  max="30"
                  class="w-full p-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                />
              </div>
              
              <div v-if="editTournament.quarters_count > 2">
                <label class="block text-blue-200 text-xs font-semibold mb-1">Break Duration (min)</label>
                <input 
                  v-model.number="editTournament.break_duration_minutes"
                  type="number" 
                  min="1" 
                  max="10"
                  class="w-full p-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                />
              </div>
              
              <div v-if="editTournament.quarters_count > 1">
                <label class="block text-blue-200 text-xs font-semibold mb-1">Halftime Duration (min)</label>
                <input 
                  v-model.number="editTournament.halftime_duration_minutes"
                  type="number" 
                  min="0" 
                  max="20"
                  class="w-full p-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                />
              </div>
            </div>
          </div>

          <!-- Match Scheduling Configuration -->
          <div class="border border-white/20 rounded-lg p-4">
            <h4 class="text-blue-200 font-semibold mb-3">Match Scheduling</h4>
            
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block text-blue-200 text-xs font-semibold mb-1">Tournament Start Time</label>
                <input 
                  v-model="editTournament.tournament_start_time"
                  type="time" 
                  class="w-full p-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                />
              </div>
              
              <div>
                <label class="block text-blue-200 text-xs font-semibold mb-1">Gap Between Matches (min)</label>
                <input 
                  v-model.number="editTournament.match_gap_minutes"
                  type="number" 
                  min="5" 
                  max="60"
                  class="w-full p-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                />
              </div>
            </div>
          </div>

          <div class="flex space-x-3 pt-4">
            <button type="submit" class="flex-1 btn btn-primary">
              Update Tournament
            </button>
            <button 
              type="button" 
              @click="editingTournament = false"
              class="flex-1 btn btn-secondary"
            >
              Cancel
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Edit Match Settings Modal -->
    <div v-if="showEditMatchModal" class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50">
      <div class="bg-gray-900 rounded-xl p-6 border border-white/20 max-w-md w-full mx-4">
        <h3 class="text-xl font-bold text-white mb-4">Edit Match Settings</h3>
        
        <form @submit.prevent="saveMatchSettings" class="space-y-4">
          <!-- Match Duration Settings -->
          <div class="border border-white/20 rounded-lg p-4">
            <h4 class="text-blue-200 font-semibold mb-3">Match Duration</h4>
            
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block text-blue-200 text-xs font-semibold mb-1">
                  {{ editMatchData.quarters_count === 2 ? 'Halves' : 'Quarters' }}
                </label>
                <input 
                  v-model.number="editMatchData.quarters_count"
                  type="number" 
                  min="1" 
                  max="6"
                  class="w-full p-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                  required
                />
              </div>
              
              <div>
                <label class="block text-blue-200 text-xs font-semibold mb-1">
                  {{ editMatchData.quarters_count === 2 ? 'Half Length (min)' : 'Quarter Length (min)' }}
                </label>
                <input 
                  v-model.number="editMatchData.quarter_duration_minutes"
                  type="number" 
                  min="5" 
                  max="30"
                  class="w-full p-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                  required
                />
              </div>
              
              <div v-if="editMatchData.quarters_count > 2">
                <label class="block text-blue-200 text-xs font-semibold mb-1">Break Time (min)</label>
                <input 
                  v-model.number="editMatchData.break_duration_minutes"
                  type="number" 
                  min="1" 
                  max="10"
                  class="w-full p-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                  required
                />
              </div>
              
              <div v-if="editMatchData.quarters_count > 1">
                <label class="block text-blue-200 text-xs font-semibold mb-1">
                  {{ editMatchData.quarters_count === 2 ? 'Halftime (min)' : 'Halftime (min)' }}
                </label>
                <input 
                  v-model.number="editMatchData.halftime_duration_minutes"
                  type="number" 
                  min="0" 
                  max="20"
                  class="w-full p-2 bg-white/10 border border-white/20 rounded text-white text-sm"
                />
              </div>
            </div>
            
            <div class="text-xs text-white/60 mt-2">
              Total match time: {{ 
                (() => {
                  const quarters = editMatchData.quarters_count
                  const quarterDuration = editMatchData.quarter_duration_minutes
                  const breakDuration = editMatchData.break_duration_minutes
                  const halftimeDuration = editMatchData.halftime_duration_minutes
                  
                  const totalPlayingTime = quarters * quarterDuration
                  let totalBreakTime = 0
                  
                  if (quarters === 1) {
                    totalBreakTime = 0
                  } else if (quarters === 2) {
                    totalBreakTime = halftimeDuration
                  } else if (quarters > 2) {
                    const numberOfBreaks = quarters - 1
                    const regularBreaks = numberOfBreaks - 1
                    totalBreakTime = regularBreaks * breakDuration + halftimeDuration
                  }
                  
                  return totalPlayingTime + totalBreakTime
                })()
              }} minutes
            </div>
          </div>

          <div class="flex space-x-3 pt-4">
            <button type="submit" class="flex-1 btn btn-primary">
              Save Settings
            </button>
            <button 
              type="button" 
              @click="showEditMatchModal = false"
              class="flex-1 btn btn-secondary"
            >
              Cancel
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>

  <!-- Team Selection Modal for Subsequent Phases -->
  <div v-if="showTeamSelectionModal" class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
    <div class="bg-white/10 backdrop-blur-sm rounded-xl p-6 border border-white/20 w-full max-w-4xl max-h-[90vh] overflow-y-auto">
      <div class="flex justify-between items-center mb-6">
        <h3 class="text-xl font-bold text-white">Select Teams for {{ selectedDivisionForTeamSelection?.name }}</h3>
        <button @click="closeTeamSelectionModal" class="text-white hover:text-red-300">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
          </svg>
        </button>
      </div>

      <div class="space-y-6">
        <!-- Previous Phase Results -->
        <div v-if="previousPhaseResults.length > 0">
          <h4 class="text-lg font-semibold text-white mb-4">Team Positions from Previous Phase</h4>
          <div class="grid gap-4">
            <div v-for="group in previousPhaseResults" :key="group.groupId" class="bg-white/5 rounded-lg p-4">
              <h5 class="text-white font-semibold mb-3">{{ group.groupName }}</h5>
              <div class="space-y-2">
                <div v-for="(position, index) in group.teams" :key="position.id" 
                     class="flex justify-between items-center p-2 bg-white/5 rounded"
                     :class="index < 2 ? 'border-l-4 border-green-400' : 'border-l-4 border-yellow-400'">
                  <span class="text-white">{{ position.name }}</span>
                  <div class="flex space-x-2">
                    <button @click="selectTeamForPhase(position, position.name)"
                            class="btn btn-xs btn-primary">
                      Select
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div class="text-sm text-blue-300 mt-2">
            💡 These are placeholder positions. When group matches are finished, they will be replaced with actual team names.
          </div>
        </div>

        <!-- Selected Teams for This Phase -->
        <div>
          <h4 class="text-lg font-semibold text-white mb-4">Selected Teams ({{ selectedTeamsForPhase.length }})</h4>
          <div class="grid grid-cols-2 gap-4 mb-4">
            <div v-for="(team, index) in selectedTeamsForPhase" :key="team.id" 
                 class="bg-white/5 rounded-lg p-3 flex justify-between items-center">
              <div>
                <div class="text-white font-semibold">{{ team.name }}</div>
                <div class="text-blue-200 text-sm">{{ team.source }}</div>
              </div>
              <button @click="removeTeamFromSelection(index)" class="text-red-400 hover:text-red-300">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>
          </div>
        </div>

        <!-- Direct Team Selection -->
        <div>
          <h4 class="text-lg font-semibold text-white mb-4">All Available Teams</h4>
          <div class="grid grid-cols-2 gap-2 max-h-40 overflow-y-auto bg-white/5 rounded p-3">
            <label v-for="team in teams" :key="team.id" 
                   class="flex items-center space-x-2 text-sm text-white cursor-pointer">
              <input type="checkbox" 
                     :value="team.id"
                     :checked="selectedTeamsForPhase.some(t => t.id === team.id)"
                     @change="toggleTeamSelection(team, 'Direct selection')"
                     class="rounded border-white/20" />
              <span>{{ team.name }}</span>
            </label>
          </div>
        </div>
      </div>

      <div class="flex justify-end space-x-4 mt-6">
        <button @click="closeTeamSelectionModal" class="btn btn-secondary">
          Cancel
        </button>
        <button @click="confirmTeamSelection" class="btn btn-primary" 
                :disabled="selectedTeamsForPhase.length < 2">
          Generate Schedule ({{ selectedTeamsForPhase.length }} teams)
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, computed, reactive } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'

interface Tournament {
  id: string
  name: string
  start_date: string
  end_date?: string
  description?: string
  status: 'setup' | 'active' | 'finished'
  quarters_count?: number
  quarter_duration_minutes?: number
  break_duration_minutes?: number
  halftime_duration_minutes?: number
  tournament_start_time?: string
  match_gap_minutes?: number
  created_at: string
  updated_at: string
}

interface Division {
  id: string
  tournament_id: string
  name: string
  type: 'group' | 'knockout'
  order_index: number
  phase_order: number
  settings: any
  created_at: string
}

interface Group {
  id: string
  division_id: string
  name: string
  order_index: number
  created_at: string
}

interface Team {
  id: string
  name: string
  players: any[]
}

interface TeamParticipation {
  id: string
  tournament_id: string
  team_id: string
  group_id?: string
  position_in_group?: number
  created_at: string
}

interface Match {
  id: string
  team_a: string
  team_b: string
  score_a?: number
  score_b?: number
  status?: 'scheduled' | 'active' | 'finished'
  start_time?: string
  division_id?: string
  group_id?: string
  quarters_count?: number
  quarter_duration_minutes?: number
  break_duration_minutes?: number
  halftime_duration_minutes?: number
  boosters?: any
}

const router = useRouter()
const tournaments = ref<Tournament[]>([])
const selectedTournament = ref<Tournament | null>(null)
const divisions = ref<Division[]>([])
const divisionGroups = ref<Record<string, Group[]>>({})
const teams = ref<Team[]>([])
const teamParticipations = ref<TeamParticipation[]>([])
const matches = ref<Match[]>([])
const divisionMatches = ref<Record<string, Match[]>>({})
const loading = ref(true)

// Modal states
const showCreateTournament = ref(false)
const showCreateDivision = ref(false)
const editingTournament = ref(false)
const showEditMatchModal = ref(false)
const showTeamSelectionModal = ref(false)

// Team selection for subsequent phases
const selectedDivisionForTeamSelection = ref<Division | null>(null)
const previousPhaseResults = ref<any[]>([])
const selectedTeamsForPhase = ref<any[]>([])

interface TeamForPhase {
  id: string
  name: string
  source: string
}

// Form data
const newTournament = reactive({
  name: '',
  start_date: '',
  end_date: '',
  description: '',
  quarters_count: 4,
  quarter_duration_minutes: 15,
  break_duration_minutes: 2,
  halftime_duration_minutes: 10,
  tournament_start_time: '09:00',
  match_gap_minutes: 15
})

const newDivision = reactive({
  name: '',
  type: '',
  numGroups: 2,
  teamsPerGroup: 4
})

const editTournament = reactive({
  id: '',
  name: '',
  start_date: '',
  end_date: '',
  description: '',
  quarters_count: 4,
  quarter_duration_minutes: 15,
  break_duration_minutes: 2,
  halftime_duration_minutes: 10,
  tournament_start_time: '09:00',
  match_gap_minutes: 15
})

// Edit match state
const editMatchData = reactive({
  id: '',
  quarters_count: 4,
  quarter_duration_minutes: 15,
  break_duration_minutes: 2,
  halftime_duration_minutes: 10
})

async function loadTournaments() {
  try {
    const { data, error } = await supabase
      .from('tournaments')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) {
      console.error('Error loading tournaments:', error)
      return
    }

    tournaments.value = data || []
  } catch (error) {
    console.error('Error:', error)
  }
}

async function loadTeams() {
  try {
    const { data, error } = await supabase
      .from('teams')
      .select('*')
      .order('name')

    if (error) {
      console.error('Error loading teams:', error)
      return
    }

    teams.value = data || []
  } catch (error) {
    console.error('Error:', error)
  }
}

async function loadTournamentData(tournamentId: string) {
  try {
    // Load divisions
    const { data: divisionsData, error: divisionsError } = await supabase
      .from('tournament_divisions')
      .select('*')
      .eq('tournament_id', tournamentId)
      .order('order_index')

    if (divisionsError) {
      console.error('Error loading divisions:', divisionsError)
      return
    }

    divisions.value = divisionsData || []

    // Load groups for each division
    const groupsData: Record<string, Group[]> = {}
    
    for (const division of divisions.value) {
      const { data: groups, error: groupsError } = await supabase
        .from('tournament_groups')
        .select('*')
        .eq('division_id', division.id)
        .order('order_index')

      if (!groupsError && groups) {
        groupsData[division.id] = groups
      }
    }

    divisionGroups.value = groupsData

    // Load matches for each division
    const matchesData: Record<string, Match[]> = {}
    
    for (const division of divisions.value) {
      const { data: matches, error: matchesError } = await supabase
        .from('matches')
        .select('*')
        .eq('tournament_id', tournamentId) // Assuming matches have tournament_id
        .order('created_at')

      if (!matchesError && matches) {
        // Filter matches for this division if division_id exists, or assign them manually
        matchesData[division.id] = matches.filter((match: any) => 
          match.division_id === division.id || !match.division_id
        )
      }
    }

    divisionMatches.value = matchesData

    // Load team participations
    const { data: participationsData, error: participationsError } = await supabase
      .from('tournament_team_participations')
      .select('*')
      .eq('tournament_id', tournamentId)

    if (!participationsError && participationsData) {
      teamParticipations.value = participationsData
    }
  } catch (error) {
    console.error('Error loading tournament data:', error)
  }
}

async function selectTournament(tournament: Tournament) {
  selectedTournament.value = tournament
  await loadTournamentData(tournament.id)
}

async function refreshCurrentTournament() {
  if (selectedTournament.value) {
    await loadTournamentData(selectedTournament.value.id)
  }
}

// Calculate total match time based on configuration
function calculateTotalMatchTime() {
  const quarters = newTournament.quarters_count || 4
  const quarterDuration = newTournament.quarter_duration_minutes || 15
  const breakDuration = newTournament.break_duration_minutes || 2
  const halftimeDuration = newTournament.halftime_duration_minutes || 10
  
  // Total playing time
  const totalPlayingTime = quarters * quarterDuration
  
  // Total break time
  let totalBreakTime = 0
  if (quarters === 1) {
    // Single quarter game - no breaks at all
    totalBreakTime = 0
  } else if (quarters === 2) {
    // For 2-quarter game (halves), only halftime between them
    totalBreakTime = halftimeDuration
  } else if (quarters > 2) {
    // For multi-quarter games, breaks between quarters plus halftime
    const numberOfBreaks = quarters - 1
    const regularBreaks = numberOfBreaks - 1 // All breaks except halftime
    totalBreakTime = regularBreaks * breakDuration + halftimeDuration
  }
  
  return totalPlayingTime + totalBreakTime
}

// Calculate total match time for selected tournament
function calculateSelectedTournamentMatchTime() {
  if (!selectedTournament.value) return 0
  
  const quarters = selectedTournament.value.quarters_count || 4
  const quarterDuration = selectedTournament.value.quarter_duration_minutes || 15
  const breakDuration = selectedTournament.value.break_duration_minutes || 2
  const halftimeDuration = selectedTournament.value.halftime_duration_minutes || 10
  
  // Total playing time
  const totalPlayingTime = quarters * quarterDuration
  
  // Total break time
  let totalBreakTime = 0
  if (quarters === 1) {
    // Single quarter game - no breaks at all
    totalBreakTime = 0
  } else if (quarters === 2) {
    // For 2-quarter game (halves), only halftime between them
    totalBreakTime = halftimeDuration
  } else if (quarters > 2) {
    // For multi-quarter games, breaks between quarters plus halftime
    const numberOfBreaks = quarters - 1
    const regularBreaks = numberOfBreaks - 1 // All breaks except halftime
    totalBreakTime = regularBreaks * breakDuration + halftimeDuration
  }
  
  return totalPlayingTime + totalBreakTime
}

// Format time from HH:MM:SS or HH:MM to HH:MM
function formatTime(timeString?: string) {
  if (!timeString) return null
  // Handle both HH:MM:SS and HH:MM formats
  return timeString.substring(0, 5)
}

// Calculate match start times based on tournament configuration
function calculateMatchStartTimes(tournament: Tournament, matchCount: number): string[] {
  const startTimes: string[] = []
  const startTime = tournament.tournament_start_time || '09:00:00'
  const matchDuration = calculateTournamentMatchDuration(tournament)
  const gapMinutes = tournament.match_gap_minutes || 15
  const totalSlotMinutes = matchDuration + gapMinutes
  
  // Parse start time
  const timeParts = startTime.substring(0, 5).split(':').map(Number)
  const hours = timeParts[0] || 9
  const minutes = timeParts[1] || 0
  let currentTime = hours * 60 + minutes // Convert to minutes
  
  for (let i = 0; i < matchCount; i++) {
    // Wrap time to stay within 24-hour range (0-1439 minutes)
    const validTime = currentTime % 1440 // 1440 minutes = 24 hours
    const matchHours = Math.floor(validTime / 60)
    const matchMinutes = validTime % 60
    startTimes.push(`${matchHours.toString().padStart(2, '0')}:${matchMinutes.toString().padStart(2, '0')}:00`)
    currentTime += totalSlotMinutes
  }
  
  return startTimes
}

// Calculate match duration for a tournament
function calculateTournamentMatchDuration(tournament: Tournament): number {
  const quarters = tournament.quarters_count || 4
  const quarterDuration = tournament.quarter_duration_minutes || 15
  const breakDuration = tournament.break_duration_minutes || 2
  const halftimeDuration = tournament.halftime_duration_minutes || 10
  
  const totalPlayingTime = quarters * quarterDuration
  
  let totalBreakTime = 0
  if (quarters === 1) {
    // Single quarter game - no breaks at all
    totalBreakTime = 0
  } else if (quarters === 2) {
    // For 2-quarter game (halves), only halftime between them
    totalBreakTime = halftimeDuration
  } else if (quarters > 2) {
    // For multi-quarter games, breaks between quarters plus halftime
    const numberOfBreaks = quarters - 1
    const regularBreaks = numberOfBreaks - 1 // All breaks except halftime
    totalBreakTime = regularBreaks * breakDuration + halftimeDuration
  }
  
  return totalPlayingTime + totalBreakTime
}

async function createTournament() {
  try {
    const tournamentData = {
      name: newTournament.name,
      start_date: newTournament.start_date,
      end_date: newTournament.end_date || null,
      description: newTournament.description || null,
      quarters_count: newTournament.quarters_count,
      quarter_duration_minutes: newTournament.quarter_duration_minutes,
      break_duration_minutes: newTournament.break_duration_minutes,
      halftime_duration_minutes: newTournament.halftime_duration_minutes,
      tournament_start_time: newTournament.tournament_start_time + ':00', // Convert to HH:MM:SS format
      match_gap_minutes: newTournament.match_gap_minutes
    }

    const { data, error } = await supabase
      .from('tournaments')
      .insert([tournamentData])
      .select()
      .single()

    if (error) {
      console.error('Error creating tournament:', error)
      return
    }

    tournaments.value.unshift(data)
    selectedTournament.value = data
    showCreateTournament.value = false
    resetNewTournament()
  } catch (error) {
    console.error('Error:', error)
  }
}

async function createDivision() {
  if (!selectedTournament.value) return

  try {
    const divisionData = {
      tournament_id: selectedTournament.value.id,
      name: newDivision.name,
      type: newDivision.type,
      order_index: divisions.value.length,
      phase_order: divisions.value.length,
      settings: newDivision.type === 'group' ? {
        num_groups: newDivision.numGroups,
        teams_per_group: newDivision.teamsPerGroup
      } : {}
    }

    const { data: division, error: divisionError } = await supabase
      .from('tournament_divisions')
      .insert([divisionData])
      .select()
      .single()

    if (divisionError) {
      console.error('Error creating division:', divisionError)
      return
    }

    divisions.value.push(division)

    // Create groups if it's a group division
    if (newDivision.type === 'group') {
      const groups = []
      for (let i = 0; i < newDivision.numGroups; i++) {
        const groupName = String.fromCharCode(65 + i) // A, B, C, etc.
        groups.push({
          division_id: division.id,
          name: `Group ${groupName}`,
          order_index: i
        })
      }

      const { data: groupsData, error: groupsError } = await supabase
        .from('tournament_groups')
        .insert(groups)
        .select()

      if (!groupsError && groupsData) {
        divisionGroups.value[division.id] = groupsData
      }
    }

    showCreateDivision.value = false
    resetNewDivision()
  } catch (error) {
    console.error('Error:', error)
  }
}

async function updateTournament() {
  if (!selectedTournament.value) return

  try {
    const { error } = await supabase
      .from('tournaments')
      .update({
        name: editTournament.name,
        start_date: editTournament.start_date,
        end_date: editTournament.end_date || null,
        description: editTournament.description || null,
        quarters_count: editTournament.quarters_count,
        quarter_duration_minutes: editTournament.quarter_duration_minutes,
        break_duration_minutes: editTournament.break_duration_minutes,
        halftime_duration_minutes: editTournament.halftime_duration_minutes,
        tournament_start_time: editTournament.tournament_start_time + ':00',
        match_gap_minutes: editTournament.match_gap_minutes
      })
      .eq('id', editTournament.id)

    if (error) {
      console.error('Error updating tournament:', error)
      return
    }

    // Update local data
    selectedTournament.value = {
      ...selectedTournament.value,
      name: editTournament.name,
      start_date: editTournament.start_date,
      end_date: editTournament.end_date,
      description: editTournament.description,
      quarters_count: editTournament.quarters_count,
      quarter_duration_minutes: editTournament.quarter_duration_minutes,
      break_duration_minutes: editTournament.break_duration_minutes,
      halftime_duration_minutes: editTournament.halftime_duration_minutes,
      tournament_start_time: editTournament.tournament_start_time + ':00',
      match_gap_minutes: editTournament.match_gap_minutes
    }

    const tournamentIndex = tournaments.value.findIndex(t => t.id === editTournament.id)
    if (tournamentIndex !== -1) {
      tournaments.value[tournamentIndex] = { ...selectedTournament.value }
    }

    editingTournament.value = false
    
    // Ask user if they want to update match schedules when tournament timing settings changed
    const shouldUpdateSchedules = confirm(
      'Tournament timing settings have been updated. Do you want to recalculate all match start times?\n\n' +
      'This will update the scheduled start times for all matches based on the new settings.\n' +
      'Choose "OK" to update schedules or "Cancel" to keep existing times.'
    )
    
    if (shouldUpdateSchedules) {
      await updateMatchSchedules()
    }
  } catch (error) {
    console.error('Error:', error)
  }
}

// Function to update all match schedules when tournament settings change
async function updateMatchSchedules() {
  if (!selectedTournament.value) return
  
  try {
    console.log('Updating match schedules for tournament:', selectedTournament.value.name)
    
    // Get all existing matches for this tournament
    const { data: matches, error: fetchError } = await supabase
      .from('matches')
      .select('id, division_id, tournament_id')
      .eq('tournament_id', selectedTournament.value.id)
      .order('division_id')
      .order('id')
    
    if (fetchError) {
      console.error('Error fetching matches for schedule update:', fetchError)
      alert('Failed to load matches for schedule update. Please try again.')
      return
    }
    
    if (!matches || matches.length === 0) {
      // No matches to update
      console.log('No matches found to update')
      return
    }
    
    console.log(`Found ${matches.length} matches to update`)
    
    // Group matches by division
    const matchesByDivision = new Map()
    matches.forEach(match => {
      if (!matchesByDivision.has(match.division_id)) {
        matchesByDivision.set(match.division_id, [])
      }
      matchesByDivision.get(match.division_id).push(match)
    })
    
    // Update start times for each division's matches
    const updates: Array<{ id: string; start_time: string }> = []
    for (const [divisionId, divisionMatches] of matchesByDivision) {
      const division = divisions.value.find(d => d.id === divisionId)
      if (!division) continue
      
      divisionMatches.forEach((match: any, index: number) => {
        const newStartTime = calculateDivisionMatchStartTime(division, index)
        updates.push({
          id: match.id,
          start_time: newStartTime
        })
      })
    }
    
    // Batch update all match start times
    if (updates.length > 0) {
      let updateCount = 0
      for (const update of updates) {
        const { error: updateError } = await supabase
          .from('matches')
          .update({ start_time: update.start_time })
          .eq('id', update.id)
        
        if (updateError) {
          console.error(`Error updating match ${update.id} start time:`, updateError)
        } else {
          updateCount++
        }
      }
      
      console.log(`Successfully updated start times for ${updateCount}/${updates.length} matches`)
      
      if (updateCount > 0) {
        // Reload tournament data to reflect the changes
        await loadTournamentData(selectedTournament.value.id)
        alert(`Successfully updated start times for ${updateCount} matches!`)
      } else {
        alert('Failed to update match schedules. Please try again.')
      }
    }
    
  } catch (error) {
    console.error('Error updating match schedules:', error)
    alert('An error occurred while updating match schedules. Please try again.')
  }
}

async function startTournament() {
  if (!selectedTournament.value) return

  try {
    const { error } = await supabase
      .from('tournaments')
      .update({ status: 'active' })
      .eq('id', selectedTournament.value.id)

    if (error) {
      console.error('Error starting tournament:', error)
      return
    }

    selectedTournament.value.status = 'active'
    const tournamentIndex = tournaments.value.findIndex(t => t.id === selectedTournament.value!.id)
    if (tournamentIndex !== -1 && tournaments.value[tournamentIndex]) {
      tournaments.value[tournamentIndex].status = 'active'
    }
  } catch (error) {
    console.error('Error:', error)
  }
}

async function deleteDivision(divisionId: string) {
  if (!confirm('Are you sure you want to delete this division? This will remove all groups and matches associated with it.')) {
    return
  }

  try {
    const { error } = await supabase
      .from('tournament_divisions')
      .delete()
      .eq('id', divisionId)

    if (error) {
      console.error('Error deleting division:', error)
      return
    }

    divisions.value = divisions.value.filter(d => d.id !== divisionId)
    delete divisionGroups.value[divisionId]
  } catch (error) {
    console.error('Error:', error)
  }
}

// Match editing functions
function editMatch(match: Match) {
  // Get default values - prefer tournament defaults, fallback to system defaults
  const defaultQuarters = selectedTournament.value?.quarters_count || 4
  const defaultQuarterDuration = selectedTournament.value?.quarter_duration_minutes || 15
  const defaultBreakDuration = selectedTournament.value?.break_duration_minutes || 2
  const defaultHalftimeDuration = selectedTournament.value?.halftime_duration_minutes || 10

  // Populate edit form with current match values or smart defaults
  editMatchData.id = match.id
  editMatchData.quarters_count = match.quarters_count || defaultQuarters
  editMatchData.quarter_duration_minutes = match.quarter_duration_minutes || defaultQuarterDuration
  editMatchData.break_duration_minutes = match.break_duration_minutes || defaultBreakDuration
  editMatchData.halftime_duration_minutes = match.halftime_duration_minutes || defaultHalftimeDuration

  showEditMatchModal.value = true
}

async function saveMatchSettings() {
  try {
    const { error } = await supabase
      .from('matches')
      .update({
        quarters_count: editMatchData.quarters_count,
        quarter_duration_minutes: editMatchData.quarter_duration_minutes,
        break_duration_minutes: editMatchData.break_duration_minutes,
        halftime_duration_minutes: editMatchData.halftime_duration_minutes
      })
      .eq('id', editMatchData.id)

    if (error) {
      console.error('Error updating match settings:', error)
      alert('Failed to save match settings. Please try again.')
      return
    }

    // Update match in local state
    const updateMatch = (matchArray: Match[]) => {
      const matchIndex = matchArray.findIndex(m => m.id === editMatchData.id)
      if (matchIndex !== -1 && matchArray[matchIndex]) {
        const match = matchArray[matchIndex]
        match.quarters_count = editMatchData.quarters_count
        match.quarter_duration_minutes = editMatchData.quarter_duration_minutes
        match.break_duration_minutes = editMatchData.break_duration_minutes
        match.halftime_duration_minutes = editMatchData.halftime_duration_minutes
      }
    }

    // Update in matches array
    updateMatch(matches.value)
    
    // Update in division matches
    for (const divisionId in divisionMatches.value) {
      if (divisionMatches.value[divisionId]) {
        updateMatch(divisionMatches.value[divisionId])
      }
    }

    showEditMatchModal.value = false
    console.log('✅ Match settings saved successfully')
  } catch (error) {
    console.error('Error saving match settings:', error)
    alert('Failed to save match settings. Please try again.')
  }
}

async function deleteMatch(matchId: string) {
  if (!confirm('Are you sure you want to delete this match? This action cannot be undone.')) {
    return
  }

  try {
    const { error } = await supabase
      .from('matches')
      .delete()
      .eq('id', matchId)

    if (error) {
      console.error('Error deleting match:', error)
      alert('Failed to delete match. Please try again.')
      return
    }

    // Remove match from local state
    matches.value = matches.value.filter(m => m.id !== matchId)
    
    // Also remove from division matches
    for (const divisionId in divisionMatches.value) {
      const divMatches = divisionMatches.value[divisionId]
      if (divMatches) {
        divisionMatches.value[divisionId] = divMatches.filter(m => m.id !== matchId)
      }
    }
    
    console.log('✅ Match deleted successfully')
  } catch (error) {
    console.error('Error:', error)
    alert('Failed to delete match. Please try again.')
  }
}

async function deleteTournament(tournamentId: string) {
  const tournament = tournaments.value.find(t => t.id === tournamentId)
  if (!tournament) return

  const confirmMessage = `Are you sure you want to delete "${tournament.name}"? This will permanently delete:\n\n• The tournament and all its settings\n• All divisions and groups\n• All matches (scheduled and completed)\n• All team participations\n\nThis action cannot be undone.`
  
  if (!confirm(confirmMessage)) {
    return
  }

  try {
    // Delete in the correct order to respect foreign key constraints
    
    // 1. Delete all matches for this tournament
    const { error: matchesError } = await supabase
      .from('matches')
      .delete()
      .eq('tournament_id', tournamentId)

    if (matchesError) {
      console.error('Error deleting matches:', matchesError)
      alert('Failed to delete tournament matches. Please try again.')
      return
    }

    // 2. Delete all team participations
    const { error: participationsError } = await supabase
      .from('tournament_team_participations')
      .delete()
      .eq('tournament_id', tournamentId)

    if (participationsError) {
      console.error('Error deleting team participations:', participationsError)
      alert('Failed to delete team participations. Please try again.')
      return
    }

    // 3. Delete all tournament groups
    const { error: groupsError } = await supabase
      .from('tournament_groups')
      .delete()
      .in('division_id', divisions.value.filter(d => d.tournament_id === tournamentId).map(d => d.id))

    if (groupsError) {
      console.error('Error deleting tournament groups:', groupsError)
      alert('Failed to delete tournament groups. Please try again.')
      return
    }

    // 4. Delete all divisions
    const { error: divisionsError } = await supabase
      .from('tournament_divisions')
      .delete()
      .eq('tournament_id', tournamentId)

    if (divisionsError) {
      console.error('Error deleting divisions:', divisionsError)
      alert('Failed to delete divisions. Please try again.')
      return
    }

    // 5. Finally delete the tournament itself
    const { error: tournamentError } = await supabase
      .from('tournaments')
      .delete()
      .eq('id', tournamentId)

    if (tournamentError) {
      console.error('Error deleting tournament:', tournamentError)
      alert('Failed to delete tournament. Please try again.')
      return
    }

    // Update local state
    tournaments.value = tournaments.value.filter(t => t.id !== tournamentId)
    
    // Clear selected tournament if it was the one deleted
    if (selectedTournament.value?.id === tournamentId) {
      selectedTournament.value = null
      divisions.value = []
      matches.value = []
    }

    console.log('✅ Tournament deleted successfully')
    alert('Tournament deleted successfully!')
    
  } catch (error) {
    console.error('Error:', error)
    alert('Failed to delete tournament. Please try again.')
  }
}

function manageDivision(division: Division) {
  // Navigate to division management
  router.push(`/admin/tournaments/division/${division.id}`)
}

function resetNewTournament() {
  newTournament.name = ''
  newTournament.start_date = ''
  newTournament.end_date = ''
  newTournament.description = ''
  newTournament.quarters_count = 4
  newTournament.quarter_duration_minutes = 15
  newTournament.break_duration_minutes = 2
  newTournament.halftime_duration_minutes = 10
  newTournament.tournament_start_time = '09:00'
  newTournament.match_gap_minutes = 15
}

function resetNewDivision() {
  newDivision.name = ''
  newDivision.type = ''
  newDivision.numGroups = 2
  newDivision.teamsPerGroup = 4
}

function formatDate(dateString: string) {
  return new Date(dateString).toLocaleDateString()
}

function getStatusClass(status: string) {
  switch (status) {
    case 'setup':
      return 'bg-yellow-500/20 text-yellow-300'
    case 'active':
      return 'bg-green-500/20 text-green-300'
    case 'finished':
      return 'bg-blue-500/20 text-blue-300'
    default:
      return 'bg-gray-500/20 text-gray-300'
  }
}

function getGroupTeamCount(groupId: string): number {
  return teamParticipations.value.filter(tp => tp.group_id === groupId).length
}

function getDivisionTeamCount(divisionId: string): number {
  if (!selectedTournament.value) return 0
  
  // For group divisions, count teams assigned to groups within that division
  const groups = divisionGroups.value[divisionId] || []
  const groupIds = groups.map((g: Group) => g.id)
  const teamsInGroups = teamParticipations.value.filter(tp => tp.group_id && groupIds.includes(tp.group_id)).length
  
  // For knockout divisions, count teams assigned to tournament but not in any group
  // We'll need to identify knockout teams differently in a proper implementation
  // For now, this works for group divisions
  return teamsInGroups
}

// Match management functions
function getDivisionMatches(division: Division): Match[] {
  return divisionMatches.value[division.id] || []
}

function getDivisionMatchCount(division: Division): number {
  return getDivisionMatches(division).length
}

function getTotalTournamentMatches(): number {
  return divisions.value.reduce((total, division) => {
    return total + getDivisionMatchCount(division)
  }, 0)
}

function getTeamName(teamId: string): string {
  const team = teams.value.find(t => t.id === teamId)
  return team ? team.name : `Team ${teamId.substring(0, 8)}`
}

function calculateDivisionMatchStartTime(division: Division, matchIndex: number): string {
  if (!selectedTournament.value) return '09:00:00'
  
  const tournamentStartTimes = calculateMatchStartTimes(selectedTournament.value, 100) // Calculate many slots
  const divisionStartIndex = divisions.value.findIndex(d => d.id === division.id) * 10 // Offset by division
  return tournamentStartTimes[divisionStartIndex + matchIndex] || '09:00:00'
}

async function generateDivisionSchedule(division: Division) {
  try {
    if (!selectedTournament.value) {
      alert('No tournament selected')
      return
    }

    // Check if this is a subsequent phase that needs team selection from previous phases
    const divisionIndex = divisions.value.findIndex(d => d.id === division.id)
    const isSubsequentPhase = divisionIndex > 0
    
    if (isSubsequentPhase && division.type !== 'group') {
      // For subsequent phases, show team selection modal
      await showTeamSelectionModalForDivision(division)
      return
    }

    // Get teams assigned to this tournament and division
    const { data: participations, error: participationsError } = await supabase
      .from('tournament_team_participations')
      .select(`
        *,
        teams:team_id (id, name, players),
        tournament_groups:group_id (id, name, division_id)
      `)
      .eq('tournament_id', selectedTournament.value.id)
    
    if (participationsError) {
      console.error('Error fetching team participations:', participationsError)
      alert('Failed to load team assignments. Please try again.')
      return
    }

    // Filter teams that are in groups belonging to this division
    const divisionTeams = participations?.filter(p => 
      p.tournament_groups?.division_id === division.id
    ).map(p => p.teams) || []
    
    if (divisionTeams.length < 2) {
      alert(`Need at least 2 teams assigned to this division to generate matches. Currently ${divisionTeams.length} teams assigned.`)
      return
    }

    // Check if matches already exist for this division
    const { data: existingMatches } = await supabase
      .from('matches')
      .select('id')
      .eq('division_id', division.id)
      .eq('tournament_id', selectedTournament.value.id)

    if (existingMatches && existingMatches.length > 0) {
      const confirmed = confirm(`This division already has ${existingMatches.length} matches. Do you want to delete them and generate new ones?`)
      if (!confirmed) return
      
      // Delete existing matches
      const { error: deleteError } = await supabase
        .from('matches')
        .delete()
        .eq('division_id', division.id)
        .eq('tournament_id', selectedTournament.value.id)
        
      if (deleteError) {
        console.error('Error deleting existing matches:', deleteError)
        alert('Failed to delete existing matches. Please try again.')
        return
      }
    }

    // Generate matches based on division type
    const matches: any[] = []
    const quarterDuration = selectedTournament.value.quarter_duration_minutes || 15
    const quartersCount = selectedTournament.value.quarters_count || 4
    const totalMatchDuration = quarterDuration * quartersCount * 60 // in seconds
    
    if (division.type === 'group') {
      // Round-robin for group divisions - every team plays every other team
      for (let i = 0; i < divisionTeams.length; i++) {
        for (let j = i + 1; j < divisionTeams.length; j++) {
          const teamA = divisionTeams[i]
          const teamB = divisionTeams[j]
          if (!teamA || !teamB) continue
          
          const matchStartTime = calculateDivisionMatchStartTime(division, matches.length)
          
          const matchData: any = {
            team_a: teamA.id,
            team_b: teamB.id,
            status: 'pending',
            division_id: division.id,
            tournament_id: selectedTournament.value.id,
            match_type: 'group',
            score_a: 0,
            score_b: 0,
            time_left: totalMatchDuration,
            maddie: false,
            boosters: {},
            cards: {},
            start_time: matchStartTime
          }
          
          matches.push(matchData)
        }
      }
    } else if (division.type === 'knockout') {
      // Single elimination for knockout divisions
      // First round matches
      for (let i = 0; i < divisionTeams.length - 1; i += 2) {
        const teamA = divisionTeams[i]
        const teamB = divisionTeams[i + 1]
        if (!teamA || !teamB) continue
        
        const matchStartTime = calculateDivisionMatchStartTime(division, matches.length)
        
        const matchData: any = {
          team_a: teamA.id,
          team_b: teamB.id,
          status: 'pending',
          division_id: division.id,
          tournament_id: selectedTournament.value.id,
          match_type: 'knockout',
          round_number: 1,
          match_order: matches.length,
          score_a: 0,
          score_b: 0,
          time_left: totalMatchDuration,
          maddie: false,
          boosters: {},
          cards: {},
          start_time: matchStartTime
        }
        
        matches.push(matchData)
      }
    }

    if (matches.length === 0) {
      alert('No matches could be generated. Check division configuration and team assignments.')
      return
    }

    // Save matches to database
    const { data, error } = await supabase
      .from('matches')
      .insert(matches)
      .select()

    if (error) {
      console.error('Error saving matches:', error)
      alert('Failed to save matches to database. Please try again.')
      return
    }

    // Update local state with new matches and reload division matches
    if (data) {
      await loadTournamentData(selectedTournament.value.id) // Reload tournament data to update matches display
      console.log(`Generated and saved ${data.length} matches for division: ${division.name}`)
      alert(`Successfully generated ${data.length} matches for ${division.name}!`)
    }
    
  } catch (error) {
    console.error('Error generating schedule:', error)
    alert('An error occurred while generating the schedule. Please try again.')
  }
}

// Team selection functions for subsequent phases
async function showTeamSelectionModalForDivision(division: Division) {
  selectedDivisionForTeamSelection.value = division
  selectedTeamsForPhase.value = []
  await loadPreviousPhaseResults(division)
  showTeamSelectionModal.value = true
}

async function loadPreviousPhaseResults(division: Division) {
  try {
    if (!selectedTournament.value) return
    
    // Find the previous division (group phase)
    const divisionIndex = divisions.value.findIndex(d => d.id === division.id)
    if (divisionIndex <= 0) return
    
    const previousDivision = divisions.value[divisionIndex - 1]
    if (!previousDivision || previousDivision.type !== 'group') return
    
    // Get groups from previous division
    const previousGroups = divisionGroups.value[previousDivision.id] || []
    
    const results = []
    
    for (const group of previousGroups) {
      // Create placeholder positions for each group
      const groupPositions = []
      for (let position = 1; position <= 4; position++) {
        groupPositions.push({
          id: `${group.id}_position_${position}`,
          name: `${position}${getPositionSuffix(position)} from ${group.name}`,
          position: position,
          groupId: group.id,
          groupName: group.name,
          isPlaceholder: true
        })
      }
      
      results.push({
        groupId: group.id,
        groupName: group.name,
        teams: groupPositions
      })
    }
    
    previousPhaseResults.value = results
  } catch (error) {
    console.error('Error loading previous phase results:', error)
  }
}

function getPositionSuffix(position: number): string {
  switch (position) {
    case 1: return 'st'
    case 2: return 'nd'
    case 3: return 'rd'
    default: return 'th'
  }
}

function selectTeamForPhase(team: any, source: string) {
  if (!selectedTeamsForPhase.value.some(t => t.id === team.id)) {
    selectedTeamsForPhase.value.push({
      id: team.id,
      name: team.name,
      source: source
    })
  }
}

function removeTeamFromSelection(index: number) {
  selectedTeamsForPhase.value.splice(index, 1)
}

function toggleTeamSelection(team: any, source: string) {
  const existingIndex = selectedTeamsForPhase.value.findIndex(t => t.id === team.id)
  if (existingIndex >= 0) {
    selectedTeamsForPhase.value.splice(existingIndex, 1)
  } else {
    selectedTeamsForPhase.value.push({
      id: team.id,
      name: team.name,
      source: source
    })
  }
}

function closeTeamSelectionModal() {
  showTeamSelectionModal.value = false
  selectedDivisionForTeamSelection.value = null
  selectedTeamsForPhase.value = []
  previousPhaseResults.value = []
}

async function confirmTeamSelection() {
  if (!selectedDivisionForTeamSelection.value || selectedTeamsForPhase.value.length < 2) {
    return
  }
  
  const division = selectedDivisionForTeamSelection.value
  const selectedTeams = selectedTeamsForPhase.value
  
  console.log('🏒 confirmTeamSelection called with:', {
    division: division.name,
    divisionType: division.type,
    selectedTeamsCount: selectedTeams.length,
    selectedTeams: selectedTeams
  })
  
  // Separate placeholder teams from actual teams
  const placeholderTeams = selectedTeams.filter(team => team.id.includes('_position_'))
  const actualTeams = selectedTeams.filter(team => !team.id.includes('_position_'))
  
  try {
    // Save actual team participations
    if (actualTeams.length > 0) {
      const teamParticipations = actualTeams.map(team => ({
        tournament_id: selectedTournament.value!.id,
        team_id: team.id,
        group_id: null,
        position_in_group: null
      }))
      
      const { error } = await supabase
        .from('tournament_team_participations')
        .upsert(teamParticipations, {
          onConflict: 'tournament_id,team_id'
        })
      
      if (error) {
        console.error('Error saving team assignments:', error)
        alert('Failed to assign teams. Please try again.')
        return
      }
    }
    
    // Generate matches with placeholder teams
    await generateMatchesWithPlaceholders(division, selectedTeams)
    
    // Close modal
    closeTeamSelectionModal()
    
  } catch (error) {
    console.error('Error confirming team selection:', error)
    alert('An error occurred. Please try again.')
  }
}

async function generateMatchesWithPlaceholders(division: Division, selectedTeams: any[]) {
  if (!selectedTournament.value) return

  console.log('🏒 generateMatchesWithPlaceholders called with:', {
    division: division.name,
    divisionType: division.type,
    selectedTeamsCount: selectedTeams.length,
    selectedTeams: selectedTeams
  })

  // Check if matches already exist for this division
  const { data: existingMatches } = await supabase
    .from('matches')
    .select('id')
    .eq('division_id', division.id)
    .eq('tournament_id', selectedTournament.value.id)

  if (existingMatches && existingMatches.length > 0) {
    const confirmed = confirm(`This division already has ${existingMatches.length} matches. Do you want to delete them and generate new ones?`)
    if (!confirmed) return
    
    // Delete existing matches
    const { error: deleteError } = await supabase
      .from('matches')
      .delete()
      .eq('division_id', division.id)
      .eq('tournament_id', selectedTournament.value.id)
      
    if (deleteError) {
      console.error('Error deleting existing matches:', deleteError)
      alert('Failed to delete existing matches. Please try again.')
      return
    }
  }

  // Generate matches with placeholders
  const matches: any[] = []
  const quarterDuration = selectedTournament.value.quarter_duration_minutes || 15
  const quartersCount = selectedTournament.value.quarters_count || 4
  const totalMatchDuration = quarterDuration * quartersCount * 60 // in seconds
  
  if (division.type === 'knockout') {
    // Generate matches for knockout phases
    for (let i = 0; i < selectedTeams.length; i += 2) {
      const teamA = selectedTeams[i]
      const teamB = selectedTeams[i + 1]
      if (!teamA || !teamB) continue
      
      const matchStartTime = calculateDivisionMatchStartTime(division, matches.length)
      
      const matchData: any = {
        // Use actual team IDs for real teams, null for placeholders  
        team_a: teamA.id.includes('_position_') ? null : teamA.id,
        team_b: teamB.id.includes('_position_') ? null : teamB.id,
        status: 'pending',
        division_id: division.id,
        tournament_id: selectedTournament.value.id,
        match_type: division.type,
        round_number: 1,
        match_order: matches.length,
        score_a: 0,
        score_b: 0,
        time_left: totalMatchDuration,
        maddie: false,
        boosters: {
          // Store placeholder information in boosters field (temporary solution)
          team_a_placeholder: teamA.id.includes('_position_') ? teamA.name : null,
          team_b_placeholder: teamB.id.includes('_position_') ? teamB.name : null,
          team_a_config: teamA.id.includes('_position_') ? {
            groupId: teamA.groupId,
            position: teamA.position,
            placeholderId: teamA.id
          } : null,
          team_b_config: teamB.id.includes('_position_') ? {
            groupId: teamB.groupId,
            position: teamB.position,
            placeholderId: teamB.id
          } : null
        },
        cards: {},
        start_time: matchStartTime
      }
      
      matches.push(matchData)
    }
  }

  console.log('🏒 Final matches array for generateMatchesWithPlaceholders:', {
    matchesCount: matches.length,
    matches: matches
  })

  if (matches.length === 0) {
    alert('No matches could be generated. Check division configuration and team assignments.')
    return
  }

  // Save matches to database
  const { data, error } = await supabase
    .from('matches')
    .insert(matches)
    .select()

  if (error) {
    console.error('Error saving matches:', error)
    alert('Failed to save matches to database. Please try again.')
    return
  }

  if (data) {
    // Update local state with new matches
    if (!divisionMatches.value[division.id]) {
      divisionMatches.value[division.id] = []
    }
    divisionMatches.value[division.id] = data
    
    console.log(`Generated and saved ${data.length} matches for division: ${division.name}`)
    alert(`Successfully generated ${data.length} matches for ${division.name} with placeholder teams!`)
  }
}

async function generateMatchesForDivision(division: Division, divisionTeams: any[]) {
  if (!selectedTournament.value) return

  // Check if matches already exist for this division
  const { data: existingMatches } = await supabase
    .from('matches')
    .select('id')
    .eq('division_id', division.id)
    .eq('tournament_id', selectedTournament.value.id)

  if (existingMatches && existingMatches.length > 0) {
    const confirmed = confirm(`This division already has ${existingMatches.length} matches. Do you want to delete them and generate new ones?`)
    if (!confirmed) return
    
    // Delete existing matches
    const { error: deleteError } = await supabase
      .from('matches')
      .delete()
      .eq('division_id', division.id)
      .eq('tournament_id', selectedTournament.value.id)
      
    if (deleteError) {
      console.error('Error deleting existing matches:', deleteError)
      alert('Failed to delete existing matches. Please try again.')
      return
    }
  }

  // Generate matches based on division type
  const matches: any[] = []
  const quarterDuration = selectedTournament.value.quarter_duration_minutes || 15
  const quartersCount = selectedTournament.value.quarters_count || 4
  const totalMatchDuration = quarterDuration * quartersCount * 60 // in seconds
  
  if (division.type === 'group') {
    // Round-robin for group divisions - every team plays every other team
    for (let i = 0; i < divisionTeams.length; i++) {
      for (let j = i + 1; j < divisionTeams.length; j++) {
        const teamA = divisionTeams[i]
        const teamB = divisionTeams[j]
        if (!teamA || !teamB) continue
        
        const matchStartTime = calculateDivisionMatchStartTime(division, matches.length)
        
        const matchData: any = {
          team_a: teamA.id,
          team_b: teamB.id,
          status: 'pending',
          division_id: division.id,
          tournament_id: selectedTournament.value.id,
          match_type: 'group',
          score_a: 0,
          score_b: 0,
          time_left: totalMatchDuration,
          maddie: false,
          boosters: {},
          cards: {},
          start_time: matchStartTime
        }
        
        matches.push(matchData)
      }
    }
  } else if (division.type === 'knockout') {
    // Single elimination for knockout divisions
    // First round matches
    for (let i = 0; i < divisionTeams.length - 1; i += 2) {
      const teamA = divisionTeams[i]
      const teamB = divisionTeams[i + 1]
      if (!teamA || !teamB) continue
      
      const matchStartTime = calculateDivisionMatchStartTime(division, matches.length)
      
      const matchData: any = {
        team_a: teamA.id,
        team_b: teamB.id,
        status: 'pending',
        division_id: division.id,
        tournament_id: selectedTournament.value.id,
        match_type: 'knockout',
        round_number: 1,
        match_order: matches.length,
        score_a: 0,
        score_b: 0,
        time_left: totalMatchDuration,
        maddie: false,
        boosters: {},
        cards: {},
        start_time: matchStartTime
      }
      
      matches.push(matchData)
    }
  }

  if (matches.length === 0) {
    alert('No matches could be generated. Check division configuration and team assignments.')
    return
  }

  // Save matches to database
  const { data, error } = await supabase
    .from('matches')
    .insert(matches)
    .select()

  if (error) {
    console.error('Error saving matches:', error)
    alert('Failed to save matches to database. Please try again.')
    return
  }

  if (data) {
    // Update local state with new matches
    if (!divisionMatches.value[division.id]) {
      divisionMatches.value[division.id] = []
    }
    divisionMatches.value[division.id] = data
    
    console.log(`Generated and saved ${data.length} matches for division: ${division.name}`)
    alert(`Successfully generated ${data.length} matches for ${division.name}!`)
  }
}

// Function to resolve placeholder teams to actual teams after group phase is complete
async function resolvePlaceholderTeams(divisionId: string) {
  if (!selectedTournament.value) return
  
  try {
    // Get matches with placeholder teams for this division
    const { data: matches, error: matchesError } = await supabase
      .from('matches')
      .select('*')
      .eq('division_id', divisionId)
      .eq('tournament_id', selectedTournament.value.id)
    
    if (matchesError) {
      console.error('Error fetching matches:', matchesError)
      return
    }
    
    for (const match of matches || []) {
      let needsUpdate = false
      const updates: any = {}
      
      // Check if team_a is a placeholder
      if (!match.team_a && match.boosters?.team_a_placeholder) {
        const config = match.boosters.team_a_config
        if (config) {
          const actualTeam = await getTeamByGroupPosition(config.groupId, config.position)
          if (actualTeam) {
            updates.team_a = actualTeam.id
            needsUpdate = true
          }
        }
      }
      
      // Check if team_b is a placeholder
      if (!match.team_b && match.boosters?.team_b_placeholder) {
        const config = match.boosters.team_b_config
        if (config) {
          const actualTeam = await getTeamByGroupPosition(config.groupId, config.position)
          if (actualTeam) {
            updates.team_b = actualTeam.id
            needsUpdate = true
          }
        }
      }
      
      // Update the match if we found actual teams
      if (needsUpdate) {
        // Clear placeholder info from boosters
        const updatedBoosters = { ...match.boosters }
        delete updatedBoosters.team_a_placeholder
        delete updatedBoosters.team_b_placeholder
        delete updatedBoosters.team_a_config
        delete updatedBoosters.team_b_config
        
        updates.boosters = updatedBoosters
        
        const { error: updateError } = await supabase
          .from('matches')
          .update(updates)
          .eq('id', match.id)
        
        if (updateError) {
          console.error('Error updating match:', updateError)
        } else {
          console.log(`Updated match ${match.id} with actual teams`)
        }
      }
    }
    
    // Refresh the division data
    await loadTournamentData(selectedTournament.value.id)
    
  } catch (error) {
    console.error('Error resolving placeholder teams:', error)
  }
}

async function getTeamByGroupPosition(groupId: string, position: number) {
  try {
    // Get team standings for this group
    const { data: standings } = await supabase
      .rpc('get_group_standings', {
        group_uuid: groupId
      })
    
    if (standings && standings.length >= position) {
      return {
        id: standings[position - 1].team_id,
        name: standings[position - 1].team_name
      }
    }
    
    return null
  } catch (error) {
    console.error('Error getting team by position:', error)
    return null
  }
}

function hasPlaceholderTeams(division: Division): boolean {
  const matches = divisionMatches.value[division.id] || []
  return matches.some(match => 
    (!match.team_a && match.boosters?.team_a_placeholder) ||
    (!match.team_b && match.boosters?.team_b_placeholder)
  )
}

async function showDivisionMatches(division: Division) {
  try {
    // Navigate to division management view
    await router.push({
      name: 'division-management',
      params: { divisionId: division.id }
    })
  } catch (error) {
    console.error('Error navigating to division:', error)
    alert('Failed to navigate to division view. Please try again.')
  }
}

function openEditTournament() {
  if (!selectedTournament.value) return
  
  editTournament.id = selectedTournament.value.id
  editTournament.name = selectedTournament.value.name
  editTournament.start_date = selectedTournament.value.start_date
  editTournament.end_date = selectedTournament.value.end_date || ''
  editTournament.description = selectedTournament.value.description || ''
  editTournament.quarters_count = selectedTournament.value.quarters_count || 4
  editTournament.quarter_duration_minutes = selectedTournament.value.quarter_duration_minutes || 15
  editTournament.break_duration_minutes = selectedTournament.value.break_duration_minutes || 2
  editTournament.halftime_duration_minutes = selectedTournament.value.halftime_duration_minutes || 10
  editTournament.tournament_start_time = formatTime(selectedTournament.value.tournament_start_time) || '09:00'
  editTournament.match_gap_minutes = selectedTournament.value.match_gap_minutes || 15
  editingTournament.value = true
}

// Watch for edit tournament trigger
function setupEditTournament() {
  if (selectedTournament.value) {
    openEditTournament()
  }
}

// Setup visibility change handler
const handleVisibilityChange = () => {
  if (!document.hidden && selectedTournament.value) {
    refreshCurrentTournament()
  }
}

onMounted(async () => {
  await Promise.all([loadTournaments(), loadTeams()])
  loading.value = false

  // Add event listener for refreshing data when user returns to tab/window
  document.addEventListener('visibilitychange', handleVisibilityChange)
})

// Cleanup event listener on unmount
onBeforeUnmount(() => {
  document.removeEventListener('visibilitychange', handleVisibilityChange)
})
</script>

<style scoped>
.btn {
  padding: 0.5rem 1rem;
  border-radius: 0.5rem;
  font-weight: 600;
  transition: all 0.2s;
  outline: none;
  border: 1px solid transparent;
}

.btn:focus {
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.5);
}

.btn-primary {
  background-color: rgb(37, 99, 235);
  color: white;
}

.btn-primary:hover {
  background-color: rgb(29, 78, 216);
}

.btn-primary:focus {
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.5);
}

.btn-secondary {
  background-color: rgba(255, 255, 255, 0.1);
  color: white;
  border-color: rgba(255, 255, 255, 0.2);
}

.btn-secondary:hover {
  background-color: rgba(255, 255, 255, 0.2);
}

.btn-secondary:focus {
  box-shadow: 0 0 0 2px rgba(255, 255, 255, 0.5);
}

.btn-success {
  background-color: rgb(22, 163, 74);
  color: white;
}

.btn-success:hover {
  background-color: rgb(21, 128, 61);
}

.btn-success:focus {
  box-shadow: 0 0 0 2px rgba(34, 197, 94, 0.5);
}

.btn-danger {
  background-color: rgb(220, 38, 38);
  color: white;
}

.btn-danger:hover {
  background-color: rgb(185, 28, 28);
}

.btn-danger:focus {
  box-shadow: 0 0 0 2px rgba(248, 113, 113, 0.5);
}

.btn-sm {
  padding: 0.25rem 0.75rem;
  font-size: 0.875rem;
}

.btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-xs {
  padding: 0.125rem 0.375rem;
  font-size: 0.75rem;
  border-radius: 0.375rem;
}

/* Tournament card hover effects for delete button */
.relative:hover .opacity-0 {
  opacity: 1;
}

/* Delete button specific styles */
.bg-red-600 {
  background-color: rgb(220, 38, 38);
}

.bg-red-600:hover {
  background-color: rgb(185, 28, 28);
}

.hover\\:bg-red-700:hover {
  background-color: rgb(153, 27, 27);
}
</style>