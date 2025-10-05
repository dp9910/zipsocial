import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { post_id, vote } = await req.json()
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
  )
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    return new Response("Unauthorized", { status: 401 })
  }

  const { data, error } = await supabase
    .from('post_interactions')
    .select('*')
    .eq('post_id', post_id)
    .eq('user_id', user.id)
    .single()

  if (error && error.code !== 'PGRST116') { // PGRST116: no rows found
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }

  if (data) {
    // Interaction exists, update it
    const newVote = data.vote === vote ? null : vote
    const { error: updateError } = await supabase
      .from('post_interactions')
      .update({ vote: newVote, updated_at: new Date().toISOString() })
      .eq('id', data.id)
    
    if (updateError) {
      return new Response(JSON.stringify({ error: updateError.message }), { status: 500 })
    }
  } else {
    // No interaction, create it
    const { error: insertError } = await supabase
      .from('post_interactions')
      .insert({ post_id, user_id: user.id, vote })

    if (insertError) {
      return new Response(JSON.stringify({ error: insertError.message }), { status: 500 })
    }
  }

  // Update upvotes and downvotes count on posts table
  const { count: upvotes } = await supabase.from('post_interactions').select('id', { count: 'exact' }).eq('post_id', post_id).eq('vote', 'up')
  const { count: downvotes } = await supabase.from('post_interactions').select('id', { count: 'exact' }).eq('post_id', post_id).eq('vote', 'down')

  const { error: postUpdateError } = await supabase
    .from('posts')
    .update({ 
      upvotes: upvotes ?? 0,
      downvotes: downvotes ?? 0,
    })
    .eq('id', post_id)

  if (postUpdateError) {
    // Log the error but don't fail the request
    console.error('Error updating post counts:', postUpdateError.message)
  }

  return new Response("OK", { status: 200 })
})
