import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { email, password, nama, role, tingkat } = await req.json()

    if (!email || !password || !nama || !role) {
      return new Response(
        JSON.stringify({ error: 'Semua field wajib diisi.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    if (role !== 'ustadz' && role !== 'santri') {
      return new Response(
        JSON.stringify({ error: 'Role tidak valid.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    // Create auth user via admin API (no email confirmation needed)
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    })

    if (authError) {
      return new Response(
        JSON.stringify({ error: authError.message }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const authId = authData.user.id
    let recordId: number

    if (role === 'ustadz') {
      const { data, error } = await supabaseAdmin
        .from('ustadz')
        .insert({ nama, role: 'ustadz', auth_id: authId })
        .select('id')
        .single()

      if (error) {
        await supabaseAdmin.auth.admin.deleteUser(authId)
        return new Response(
          JSON.stringify({ error: error.message }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        )
      }
      recordId = data.id
    } else {
      const { data, error } = await supabaseAdmin
        .from('santri')
        .insert({ nama, auth_id: authId, tingkat: tingkat || 'BK1' })
        .select('id')
        .single()

      if (error) {
        await supabaseAdmin.auth.admin.deleteUser(authId)
        return new Response(
          JSON.stringify({ error: error.message }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
        )
      }
      recordId = data.id
    }

    return new Response(
      JSON.stringify({ id: recordId, auth_id: authId }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
})
