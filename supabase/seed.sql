-- Insert sample teams
INSERT INTO teams (id, name, players) VALUES
    ('550e8400-e29b-41d4-a716-446655440001', 'Lightning Bolts', '[
        {"name": "Alex Johnson", "number": 1, "position": "Forward"},
        {"name": "Sam Wilson", "number": 7, "position": "Defense"},
        {"name": "Jordan Lee", "number": 12, "position": "Goalie"},
        {"name": "Taylor Brown", "number": 23, "position": "Forward"},
        {"name": "Casey Smith", "number": 42, "position": "Defense"}
    ]'::jsonb),
    ('550e8400-e29b-41d4-a716-446655440002', 'Ice Warriors', '[
        {"name": "Morgan Davis", "number": 3, "position": "Forward"},
        {"name": "Riley Garcia", "number": 9, "position": "Defense"},
        {"name": "Avery Martinez", "number": 15, "position": "Goalie"},
        {"name": "Quinn Anderson", "number": 28, "position": "Forward"},
        {"name": "Sage Thompson", "number": 33, "position": "Defense"}
    ]'::jsonb),
    ('550e8400-e29b-41d4-a716-446655440003', 'Frozen Flames', '[
        {"name": "Harper White", "number": 5, "position": "Forward"},
        {"name": "Emery Clark", "number": 11, "position": "Defense"},
        {"name": "River Jackson", "number": 18, "position": "Goalie"},
        {"name": "Rowan Miller", "number": 21, "position": "Forward"},
        {"name": "Phoenix Wilson", "number": 36, "position": "Defense"}
    ]'::jsonb),
    ('550e8400-e29b-41d4-a716-446655440004', 'Storm Chasers', '[
        {"name": "Blake Taylor", "number": 8, "position": "Forward"},
        {"name": "Drew Johnson", "number": 14, "position": "Defense"},
        {"name": "Skylar Moore", "number": 19, "position": "Goalie"},
        {"name": "Cameron Lee", "number": 25, "position": "Forward"},
        {"name": "Reese Brown", "number": 31, "position": "Defense"}
    ]'::jsonb);

-- Insert sample matches
INSERT INTO matches (id, team_a, team_b, status, time_left) VALUES
    ('650e8400-e29b-41d4-a716-446655440001', 
     '550e8400-e29b-41d4-a716-446655440001', 
     '550e8400-e29b-41d4-a716-446655440002', 
     'pending', 1800),
    ('650e8400-e29b-41d4-a716-446655440002', 
     '550e8400-e29b-41d4-a716-446655440003', 
     '550e8400-e29b-41d4-a716-446655440004', 
     'pending', 1800);

-- Create an admin user (will be created when someone signs up with this email)
-- The trigger will handle creating the user record
-- You can manually update their role to admin after signup:
-- UPDATE users SET role = 'admin' WHERE email = 'admin@hockeymadness.com';