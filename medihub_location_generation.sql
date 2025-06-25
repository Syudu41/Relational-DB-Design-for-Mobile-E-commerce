USE medical_ecommerce;

DELIMITER //

CREATE PROCEDURE generate_location_data()
BEGIN
    -- Insert country
    INSERT INTO countries (country_name) VALUES ('United States');
    SET @us_id = LAST_INSERT_ID();

    -- Insert states
    INSERT INTO states (country_id, state_name) VALUES
    (@us_id, 'California'),
    (@us_id, 'New York'),
    (@us_id, 'Texas'),
    (@us_id, 'Florida'),
    (@us_id, 'Illinois');

    -- Insert cities for each state
    INSERT INTO cities (state_id, city_name)
    SELECT 
        s.state_id,
        city_name
    FROM states s
    CROSS JOIN (
        SELECT 'Los Angeles' as city_name UNION ALL
        SELECT 'San Francisco' UNION ALL
        SELECT 'San Diego' UNION ALL
        SELECT 'Sacramento' UNION ALL
        SELECT 'New York City' UNION ALL
        SELECT 'Buffalo' UNION ALL
        SELECT 'Houston' UNION ALL
        SELECT 'Austin' UNION ALL
        SELECT 'Miami' UNION ALL
        SELECT 'Orlando' UNION ALL
        SELECT 'Chicago' UNION ALL
        SELECT 'Springfield'
    ) cities
    WHERE 
        (s.state_name = 'California' AND cities.city_name IN ('Los Angeles', 'San Francisco', 'San Diego', 'Sacramento')) OR
        (s.state_name = 'New York' AND cities.city_name IN ('New York City', 'Buffalo')) OR
        (s.state_name = 'Texas' AND cities.city_name IN ('Houston', 'Austin')) OR
        (s.state_name = 'Florida' AND cities.city_name IN ('Miami', 'Orlando')) OR
        (s.state_name = 'Illinois' AND cities.city_name IN ('Chicago', 'Springfield'));

    -- Verify data generation
    SELECT 
        'Location Data Generation Complete' as message,
        (SELECT COUNT(*) FROM countries) as countries,
        (SELECT COUNT(*) FROM states) as states,
        (SELECT COUNT(*) FROM cities) as cities;
END //

DELIMITER ;

-- Execute the procedure
CALL generate_location_data();

-- Clean up
DROP PROCEDURE IF EXISTS generate_location_data;