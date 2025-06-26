USE medical_ecommerce;

DELIMITER //

CREATE PROCEDURE generate_base_data()
BEGIN
    -- Insert sample country
    INSERT INTO countries (country_name) VALUES ('United States');
    SET @us_id = LAST_INSERT_ID();

    -- Insert sample states
    INSERT INTO states (country_id, state_name) VALUES
    (@us_id, 'California'),
    (@us_id, 'New York'),
    (@us_id, 'Texas'),
    (@us_id, 'Florida'),
    (@us_id, 'Illinois');

    -- Insert sample cities for each state
    INSERT INTO cities (state_id, city_name)
    SELECT 
        s.state_id,
        CASE s.state_name
            WHEN 'California' THEN ELT(1 + FLOOR(RAND() * 5), 'Los Angeles', 'San Francisco', 'San Diego', 'San Jose', 'Sacramento')
            WHEN 'New York' THEN ELT(1 + FLOOR(RAND() * 5), 'New York City', 'Buffalo', 'Rochester', 'Syracuse', 'Albany')
            WHEN 'Texas' THEN ELT(1 + FLOOR(RAND() * 5), 'Houston', 'Austin', 'Dallas', 'San Antonio', 'Fort Worth')
            WHEN 'Florida' THEN ELT(1 + FLOOR(RAND() * 5), 'Miami', 'Orlando', 'Tampa', 'Jacksonville', 'Tallahassee')
            WHEN 'Illinois' THEN ELT(1 + FLOOR(RAND() * 5), 'Chicago', 'Aurora', 'Rockford', 'Joliet', 'Naperville')
        END
    FROM states s;
END //

DELIMITER ;

-- Execute the procedure
CALL generate_base_data();

-- Clean up
DROP PROCEDURE IF EXISTS generate_base_data;

-- Verify data
SELECT 'Base Data Generation Complete' as message;
SELECT 
    (SELECT COUNT(*) FROM countries) as countries_count,
    (SELECT COUNT(*) FROM states) as states_count,
    (SELECT COUNT(*) FROM cities) as cities_count;