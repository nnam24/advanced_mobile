import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:final_application/main.dart';

class Database {
  static Future<void> createProfilesTable() async {
    // This function is for reference only - you would typically create tables
    // through the Supabase dashboard or migrations
    
    // SQL to create profiles table:
    // CREATE TABLE profiles (
    //   id UUID PRIMARY KEY REFERENCES auth.users(id),
    //   username TEXT UNIQUE,
    //   avatar_url TEXT,
    //   updated_at TIMESTAMP WITH TIME ZONE
    // );
    
    // SQL to create a trigger for new users:
    // CREATE FUNCTION public.handle_new_user() 
    // RETURNS TRIGGER AS $$
    // BEGIN
    //   INSERT INTO public.profiles (id, username, avatar_url, updated_at)
    //   VALUES (new.id, new.raw_user_meta_data->>'username', null, now());
    //   RETURN new;
    // END;
    // $$ LANGUAGE plpgsql SECURITY DEFINER;
    
    // CREATE TRIGGER on_auth_user_created
    //   AFTER INSERT ON auth.users
    //   FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
  }
  
  static Future<void> setupUser(User user) async {
    // Check if user profile exists
    final userExists = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    
    // If not, create a new profile
    if (userExists == null) {
      await supabase.from('profiles').insert({
        'id': user.id,
        'username': user.userMetadata?['username'] ?? '',
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }
}

