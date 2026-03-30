export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      analysis_results: {
        Row: {
          id: string
          user_id: string
          source_type: 'image' | 'manual'
          image_filename: string | null
          ingredient_lines: Json
          raw_ocr_text: string | null
          food_name: string
          health_score: number
          result: Json
          created_at: string
        }
        Insert: {
          id?: string
          user_id: string
          source_type: 'image' | 'manual'
          image_filename?: string | null
          ingredient_lines: Json
          raw_ocr_text?: string | null
          food_name: string
          health_score: number
          result: Json
          created_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          source_type?: 'image' | 'manual'
          image_filename?: string | null
          ingredient_lines?: Json
          raw_ocr_text?: string | null
          food_name?: string
          health_score?: number
          result?: Json
          created_at?: string
        }
        Relationships: [
          {
            foreignKeyName: 'analysis_results_user_id_fkey'
            columns: ['user_id']
            referencedRelation: 'users'
            referencedColumns: ['id']
          }
        ]
      }
    }
    Views: Record<string, never>
    Functions: Record<string, never>
    Enums: Record<string, never>
    CompositeTypes: Record<string, never>
  }
}
