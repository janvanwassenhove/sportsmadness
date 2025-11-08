// Quick test script to check current matches in database
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'YOUR_SUPABASE_URL'
const supabaseKey = 'YOUR_SUPABASE_ANON_KEY'

// You'll need to replace these with actual values
const supabase = createClient(supabaseUrl, supabaseKey)

async function checkMatches() {
  try {
    const { data: matches, error } = await supabase
      .from('matches')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) {
      console.error('Error:', error)
      return
    }

    console.log('Current matches in database:')
    matches?.forEach(match => {
      console.log(`- ${match.id}: ${match.team_a} vs ${match.team_b} (${match.status})`)
    })

    const activeMatches = matches?.filter(m => m.status === 'active' || m.status === 'paused')
    console.log(`\nActive/Paused matches: ${activeMatches?.length || 0}`)
    
    if (activeMatches && activeMatches.length > 1) {
      console.log('✅ Multiple active matches - selector should show')
    } else if (activeMatches && activeMatches.length === 1) {
      console.log('✅ Single active match - should navigate directly')
    } else {
      console.log('ℹ️ No active matches - will check pending matches')
    }
  } catch (error) {
    console.error('Error:', error)
  }
}

// Uncomment and run this script if you want to test
// checkMatches()

console.log('Test script created. Update with your Supabase credentials and run to test.')