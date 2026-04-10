-- JOSEPH CLARO - PERSONAL GYM DATABASE SAMPLE QUERIES

-- Find all groups of sets performed that target the chest

SELECT sg.date,
       sg.exercise,
       e.muscle_group,
       sg.total_volume_kg
FROM setgroups sg
JOIN exercises e
    ON (e.exercise_id = sg.exercise_id)
WHERE e.muscle_group = 'Chest'
ORDER BY sg.date DESC;

-- List all gym sessions, and the # of sets per session that counted as 
-- push, pull, and legs/abs respectively

SELECT  id, 
        date, 
        gym_name, 
        sum(is_push) AS total_push_sets,
        sum(is_pull) AS total_pull_sets,
        sum(is_legs_abs) AS total_legs_abs_sets
FROM (
    SELECT  s.session_id AS id,
            s.date,
            s.gym_name,
            sg.exercise, 
            e.ppl as ppl_group,
            CASE WHEN e.ppl = 'push' THEN total_sets ELSE 0 END
                AS is_push,
            CASE WHEN e.ppl = 'pull' THEN total_sets ELSE 0 END 
                AS is_pull,
            CASE WHEN e.ppl = 'legs/abs' THEN total_sets ELSE 0 END 
                AS is_legs_abs
    FROM setgroups sg
    JOIN exercises e
        ON e.exercise_id = sg.exercise_id
    JOIN sessions s
        ON sg.session_id = s.session_id
) AS PPLcount_subq
GROUP BY id, date, gym_name
ORDER BY date ASC;

-- List all unique exercises performed, the # of times they were performed, 
-- and the percentage of times a final dropset was performed

SELECT  sg.exercise, 
        COUNT(sg.exercise) AS count,
        COUNT(sg.dropset_kg) AS dropset_count,
        100 * COUNT(sg.dropset_kg) / COUNT(sg.exercise) AS dropset_pct
FROM setgroups sg
GROUP BY sg.exercise
ORDER BY count DESC, dropset_pct DESC;


-- List all sessions and the # of days since the previous session

WITH sessions_cte AS (
     SELECT ROW_NUMBER() OVER(ORDER BY date) AS session_order,
            gym_name,
            date,
            notes   
     FROM sessions
     )
SELECT  s1.gym_name,
        s1.date AS date,
        s2.date AS prev_date,
        DATEDIFF(dy,s2.date, s1.date) AS days_since_prev,
        s1.notes
FROM sessions_cte s1
LEFT JOIN sessions_cte s2
    ON (s2.session_order = s1.session_order - 1);


-- Find the minimum/maximum set weight, per muscle targeted

SELECT  e.main_target_muscle,
        MIN(LEAST(sg.set1_kg, sg.set2_kg, sg.set3_kg)) AS min_kg,
        MAX(GREATEST(sg.set1_kg, sg.set2_kg, sg.set3_kg)) AS max_kg      
FROM setgroups sg
JOIN exercises e
    ON (sg.exercise_id = e.exercise_id)
GROUP BY e.main_target_muscle
ORDER BY max_kg DESC, min_kg DESC;


-- Find the running total weight lifted at the end of each group of sets

WITH recurs_cte AS (
    SELECT  setgroup_id,
            date,
            session_id,
            exercise,
            total_volume_kg AS running_total_kg
    FROM setgroups
    WHERE setgroup_id = (SELECT MIN(setgroup_id) FROM setgroups)

    UNION ALL

    SELECT  sg.setgroup_id,
            sg.date,
            sg.session_id,
            sg.exercise,
            sg.total_volume_kg + r.running_total_kg AS running_total_kg
            FROM setgroups sg
            JOIN recurs_cte r
                ON (sg.setgroup_id = r.setgroup_id + 1)
)
SELECT r.date, s.gym_name, r.exercise, r.running_total_kg FROM recurs_cte r
JOIN sessions s
    ON (s.session_id = r.session_id);
