-- Function to call for text in language by text ID
CREATE OR REPLACE FUNCTION get_translation_by_text_id(
    in_text_id UUID,
    in_language_code VARCHAR(10),
    in_text_type VARCHAR(10) DEFAULT 'long'
)
RETURNS TEXT AS $$
DECLARE
    translation TEXT;
BEGIN
    IF in_text_type = 'short' THEN
        SELECT short INTO translation
        FROM translations
        WHERE text_id = in_text_id AND language_code = in_language_code;
    ELSIF in_text_type = 'medium' THEN
        SELECT medium INTO translation
        FROM translations
        WHERE text_id = in_text_id AND language_code = in_language_code;
    ELSIF in_text_type = 'all' THEN
        SELECT json_build_object(
            'short', short,
            'medium', medium,
            'long', long,
            'system_text', system_text
        )::TEXT INTO translation
        FROM translations
        WHERE text_id = in_text_id AND language_code = in_language_code;
    ELSE
        SELECT long INTO translation
        FROM translations
        WHERE text_id = in_text_id AND language_code = in_language_code;
    END IF;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Translation for text_id %, language_code %, and text_type % not found', in_text_id, in_language_code, in_text_type;
    END IF;

    RETURN translation;
END;
$$ LANGUAGE plpgsql;

-- Function to call for text in language by system text
CREATE OR REPLACE FUNCTION get_translation_by_system_text(
    in_system_text VARCHAR,
    in_language_code VARCHAR(10),
    in_text_type VARCHAR(10) DEFAULT 'long'
)
RETURNS TEXT AS $$
DECLARE
    translation TEXT;
BEGIN
    IF in_text_type = 'short' THEN
        SELECT short INTO translation
        FROM translations
        WHERE system_text = in_system_text AND language_code = in_language_code;
    ELSIF in_text_type = 'medium' THEN
        SELECT medium INTO translation
        FROM translations
        WHERE system_text = in_system_text AND language_code = in_language_code;
    ELSIF in_text_type = 'all' THEN
        SELECT json_build_object(
            'short', short,
            'medium', medium,
            'long', long,
            'system_text', system_text
        )::TEXT INTO translation
        FROM translations
        WHERE system_text = in_system_text AND language_code = in_language_code;
    ELSE
        SELECT long INTO translation
        FROM translations
        WHERE system_text = in_system_text AND language_code = in_language_code;
    END IF;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Translation for system_text %, language_code %, and text_type % not found', in_system_text, in_language_code, in_text_type;
    END IF;

    RETURN translation;
END;
$$ LANGUAGE plpgsql;

-- Function to update a translation by text ID
CREATE OR REPLACE FUNCTION update_translation_by_text_id(
    in_text_id UUID,
    in_language_code VARCHAR(10),
    in_short TEXT,
    in_medium TEXT,
    in_long TEXT
)
RETURNS VOID AS $$
BEGIN
    UPDATE translations
    SET short = in_short, medium = in_medium, long = in_long
    WHERE text_id = in_text_id AND language_code = in_language_code;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Translation for system_text %, language_code %, and text_type % not found', in_system_text, in_language_code, in_text_type;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to update a translation by system text
CREATE OR REPLACE FUNCTION update_translation_by_system_text(
    in_system_text VARCHAR,
    in_language_code VARCHAR(10),
    in_short TEXT,
    in_medium TEXT,
    in_long TEXT
)
RETURNS VOID AS $$
BEGIN
    UPDATE translations
    SET short = in_short, medium = in_medium, long = in_long
    WHERE system_text = in_system_text AND language_code = in_language_code;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Translation for system_text %, language_code %, and text_type % not found', in_system_text, in_language_code, in_text_type;
    END IF;
END;
$$ LANGUAGE plpgsql;