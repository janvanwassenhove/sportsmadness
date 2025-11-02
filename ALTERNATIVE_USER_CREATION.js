// Alternative user creation approach - sends password reset email
async function createUserWithPasswordReset() {
  try {
    creating.value = true
    
    // Create user in Supabase Auth without password
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email: newUser.value.email,
      email_confirm: true
    })

    if (authError) throw authError

    // Send password reset email so user can set their own password
    const { error: resetError } = await supabase.auth.resetPasswordForEmail(
      newUser.value.email,
      {
        redirectTo: `${window.location.origin}/reset-password`
      }
    )

    if (resetError) {
      console.warn('Failed to send password reset email:', resetError)
      // Continue anyway - admin can provide password manually
    }

    // Update user profile with role and team assignment
    const { error: updateError } = await supabase
      .from('users')
      .update({
        role: newUser.value.role,
        assigned_team_id: newUser.value.role === 'team' ? newUser.value.assigned_team_id || null : null
      })
      .eq('id', authData.user.id)

    if (updateError) throw updateError

    alert(`User created successfully! ${resetError ? 'Please provide them with the password manually.' : 'Password reset email sent to user.'}`)
  } catch (error: any) {
    console.error('Error creating user:', error)
    alert(`Failed to create user: ${error.message}`)
  } finally {
    creating.value = false
  }
}