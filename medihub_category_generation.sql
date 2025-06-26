USE medical_ecommerce;

-- Insert categories
INSERT INTO categories (name, description, is_active) VALUES
('Pain Management', 'Analgesics and pain relief medications', TRUE),
('Antibiotics', 'Various antibiotic medications', TRUE),
('Cardiovascular', 'Heart and blood pressure medications', TRUE),
('Diabetes Care', 'Diabetes management medications and supplies', TRUE),
('Respiratory', 'Asthma and respiratory medications', TRUE),
('Gastrointestinal', 'Digestive health medications', TRUE),
('Mental Health', 'Mental health and neurological medications', TRUE),
('Allergy', 'Allergy medications and antihistamines', TRUE),
('Vitamins & Supplements', 'Essential vitamins and supplements', TRUE),
('First Aid', 'First aid supplies and medications', TRUE);

-- Verify categories
SELECT 'Categories created successfully' as message;
SELECT * FROM categories ORDER BY category_id;