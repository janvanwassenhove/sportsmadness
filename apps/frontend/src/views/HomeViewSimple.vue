<template>
  <div style="min-height: 100vh; background: linear-gradient(135deg, #1e40af, #3730a3); color: white; padding: 2rem;">
    <div style="max-width: 1200px; margin: 0 auto; text-align: center;">
      <h1 style="font-size: 4rem; font-weight: bold; margin-bottom: 2rem;">
        � Hockey Madness
      </h1>
      <p style="font-size: 1.25rem; margin-bottom: 3rem;">
        Real-time tournament management for hockey championships
      </p>
      
      <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 2rem; margin-top: 3rem;">
        <div style="background: rgba(255,255,255,0.1); padding: 2rem; border-radius: 12px; border: 1px solid rgba(255,255,255,0.2);">
          <div style="font-size: 3rem; margin-bottom: 1rem;">📺</div>
          <h2 style="font-size: 1.5rem; font-weight: bold; margin-bottom: 1rem;">Live Scoreboard</h2>
          <p style="margin-bottom: 1.5rem;">Watch live matches with real-time updates</p>
          <a href="/scoreboard" style="display: inline-block; background: #3b82f6; color: white; padding: 0.75rem 1.5rem; border-radius: 8px; text-decoration: none; font-weight: 500;">
            View Scoreboard
          </a>
        </div>
        
        <div style="background: rgba(255,255,255,0.1); padding: 2rem; border-radius: 12px; border: 1px solid rgba(255,255,255,0.2);">
          <div style="font-size: 3rem; margin-bottom: 1rem;">🔑</div>
          <h2 style="font-size: 1.5rem; font-weight: bold; margin-bottom: 1rem;">Admin Login</h2>
          <p style="margin-bottom: 1.5rem;">Access tournament management</p>
          <a href="/login" style="display: inline-block; background: #3b82f6; color: white; padding: 0.75rem 1.5rem; border-radius: 8px; text-decoration: none; font-weight: 500;">
            Admin Login
          </a>
        </div>
        
        <div style="background: rgba(255,255,255,0.1); padding: 2rem; border-radius: 12px; border: 1px solid rgba(255,255,255,0.2);">
          <div style="font-size: 3rem; margin-bottom: 1rem;">⚙️</div>
          <h2 style="font-size: 1.5rem; font-weight: bold; margin-bottom: 1rem;">Setup Status</h2>
          <p style="margin-bottom: 1.5rem;">Configure database connection</p>
          <div style="padding: 0.75rem 1.5rem; border-radius: 8px; background: rgba(251, 191, 36, 0.2); border: 1px solid rgba(251, 191, 36, 0.5);">
            <p style="margin: 0; font-size: 0.875rem;">⚠️ Database setup required</p>
          </div>
        </div>
      </div>
      
      <div style="margin-top: 4rem;">
        <h3 style="font-size: 2rem; font-weight: bold; margin-bottom: 2rem;">Features</h3>
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 2rem;">
          <div style="text-align: center;">
            <div style="font-size: 2rem; margin-bottom: 1rem;">⏱️</div>
            <h4 style="font-size: 1.125rem; font-weight: 600; margin-bottom: 0.5rem;">Live Timer</h4>
            <p style="color: rgba(255,255,255,0.8);">Real-time match countdown</p>
          </div>
          <div style="text-align: center;">
            <div style="font-size: 2rem; margin-bottom: 1rem;">🎯</div>
            <h4 style="font-size: 1.125rem; font-weight: 600; margin-bottom: 0.5rem;">Score Tracking</h4>
            <p style="color: rgba(255,255,255,0.8);">Instant score updates</p>
          </div>
          <div style="text-align: center;">
            <div style="font-size: 2rem; margin-bottom: 1rem;">🎪</div>
            <h4 style="font-size: 1.125rem; font-weight: 600; margin-bottom: 0.5rem;">Special Effects</h4>
            <p style="color: rgba(255,255,255,0.8);">Boosters and visual effects</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'HomeViewSimple'
}
</script>