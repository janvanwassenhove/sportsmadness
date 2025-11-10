// Sound utility functions for hockey madness

interface SoundFile {
  name: string
  path: string
  displayName: string
}

export class SoundManager {
  private static audioCache: Map<string, HTMLAudioElement> = new Map()

  // Get the correct base path for assets
  private static getBasePath(): string {
    // Use import.meta.env.BASE_URL which Vite sets automatically based on the base config
    return import.meta.env.BASE_URL || '/'
  }

  // Get available sound files from the public directory
  static async getAvailableSounds(type: 'boosters' | 'maddies'): Promise<SoundFile[]> {
    const sounds: SoundFile[] = []
    const basePath = this.getBasePath()
    
    // Pre-defined sound files based on the folder structure
    const soundFiles = type === 'boosters' 
      ? ['booster_1.mp3', 'booster_2.mp3', 'booster_3.mp3', 'booster_4.mp3']
      : ['maddie_1.mp3', 'maddie_2.mp3', 'maddie_3.mp3', 'maddie_4.mp3']

    soundFiles.forEach(file => {
      sounds.push({
        name: file,
        path: `${basePath}sounds/${type}/${file}`,
        displayName: file.replace('.mp3', '').replace('_', ' ').toUpperCase()
      })
    })

    return sounds
  }

  // Play a sound file with automatic base path resolution
  static async playSound(soundPath: string, volume: number = 0.7): Promise<void> {
    try {
      // If soundPath doesn't start with http or data: and doesn't include the base path, add it
      let fullPath = soundPath
      const basePath = this.getBasePath()
      
      if (!soundPath.startsWith('http') && 
          !soundPath.startsWith('data:') && 
          !soundPath.startsWith(basePath)) {
        // Remove leading slash if present, then add base path
        const cleanPath = soundPath.startsWith('/') ? soundPath.substring(1) : soundPath
        fullPath = `${basePath}${cleanPath}`
      }
      
      let audio = this.audioCache.get(fullPath)
      
      if (!audio) {
        audio = new Audio(fullPath)
        audio.volume = volume
        this.audioCache.set(fullPath, audio)
      }

      // Reset the audio to the beginning
      audio.currentTime = 0
      audio.volume = volume
      
      console.log('🔊 Playing sound:', fullPath)
      await audio.play()
    } catch (error) {
      console.error('🔊 Error playing sound:', soundPath, error)
    }
  }

  // Preload a sound for better performance
  static preloadSound(soundPath: string): void {
    // Apply the same base path logic as playSound
    let fullPath = soundPath
    const basePath = this.getBasePath()
    
    if (!soundPath.startsWith('http') && 
        !soundPath.startsWith('data:') && 
        !soundPath.startsWith(basePath)) {
      const cleanPath = soundPath.startsWith('/') ? soundPath.substring(1) : soundPath
      fullPath = `${basePath}${cleanPath}`
    }
    
    if (!this.audioCache.has(fullPath)) {
      const audio = new Audio(fullPath)
      audio.preload = 'auto'
      this.audioCache.set(fullPath, audio)
    }
  }

  // Upload a custom sound file
  static async uploadCustomSound(
    file: File, 
    type: 'boosters' | 'maddies',
    itemId: string
  ): Promise<string> {
    return new Promise((resolve, reject) => {
      const reader = new FileReader()
      
      reader.onload = (e) => {
        const result = e.target?.result as string
        const fileName = `custom_${type}_${itemId}_${file.name}`
        
        // Store in localStorage for now (in a real app, you'd upload to a server)
        localStorage.setItem(`sound_${fileName}`, result)
        
        console.log('📁 Custom sound uploaded:', fileName)
        resolve(`data:audio/mp3;base64,${result.split(',')[1]}`)
      }
      
      reader.onerror = () => reject(new Error('Failed to read file'))
      reader.readAsDataURL(file)
    })
  }

  // Get custom sound from storage
  static getCustomSound(fileName: string): string | null {
    return localStorage.getItem(`sound_${fileName}`)
  }

  // Validate audio file
  static isValidAudioFile(file: File): boolean {
    const validTypes = ['audio/mp3', 'audio/mpeg', 'audio/wav', 'audio/ogg']
    const validExtensions = ['.mp3', '.wav', '.ogg']
    
    const hasValidType = validTypes.includes(file.type)
    const hasValidExtension = validExtensions.some(ext => 
      file.name.toLowerCase().endsWith(ext)
    )
    
    const isValidSize = file.size <= 10 * 1024 * 1024 // 10MB limit
    
    return (hasValidType || hasValidExtension) && isValidSize
  }
}

// Export default instance
export const soundManager = SoundManager