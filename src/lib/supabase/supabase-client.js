import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://hbdjgtnuxzmnkfvvible.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhiZGpndG51eHptbmtmdnZpYmxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI3MDE3MzcsImV4cCI6MjA3ODI3NzczN30.NfeoVBSFT3sU-p7wkGHQrpMa20TFjxr_TUKbikeyE98';
export const supabase = createClient(supabaseUrl, supabaseKey);