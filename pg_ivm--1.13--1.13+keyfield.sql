ALTER TABLE pgivm.pg_ivm_immv
  ADD COLUMN key_field text;

CREATE FUNCTION pgivm.create_immv(text, text, text DEFAULT NULL)
RETURNS bigint
STRICT
AS 'MODULE_PATHNAME', 'create_immv'
LANGUAGE C;
