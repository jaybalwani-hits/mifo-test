CREATE OR REPLACE FUNCTION public.create_appointment(p_patient_id text, p_doctor_id text, p_appointment_date date, p_appointment_time time without time zone, p_visit_type text, p_status text, p_phone_number text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
  INSERT INTO "Appointment" (
    id, "patientId", "doctorId", "appointmentDate", "appointmentTime",
    type, status, source, "phoneNumber", "createdAt", "updatedAt"
  )
  VALUES (
    gen_random_uuid(), p_patient_id, p_doctor_id, p_appointment_date, p_appointment_time,
    p_visit_type::"VisitType", p_status::"AppointmentStatus", 'Import', p_phone_number,
    now(), now()
  );
END;
$function$
;


CREATE OR REPLACE FUNCTION public.upsert_doctor_schedule(p_doctor_id text, p_date date, p_start_time time without time zone, p_end_time time without time zone, p_lunch_start_time time without time zone, p_lunch_end_time time without time zone, p_services text[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
  INSERT INTO "DoctorSchedule" (
    id,
    "doctorId",
    date,
    "startTime",
    "endTime",
    "lunchStartTime",
    "lunchEndTime",
    services
  )
  VALUES (
    gen_random_uuid(),
    p_doctor_id,
    p_date,
    p_start_time,
    p_end_time,
    p_lunch_start_time,
    p_lunch_end_time,
    p_services::"VisitType"[]
  )
  ON CONFLICT ("doctorId", date) DO UPDATE SET
    "startTime" = EXCLUDED."startTime",
    "endTime" = EXCLUDED."endTime",
    "lunchStartTime" = EXCLUDED."lunchStartTime",
    "lunchEndTime" = EXCLUDED."lunchEndTime",
    services = EXCLUDED.services;
END;
$function$
;


CREATE OR REPLACE FUNCTION public.upsert_patient_and_check_duplicate_appointment(p_account_number text, p_first_name text, p_last_name text, p_full_name text, p_dob date, p_email text, p_home_phone text, p_cell_phone text, p_work_phone text, p_doctor_id text, p_appointment_date date, p_appointment_time time without time zone)
 RETURNS TABLE(patient_id text, appointment_exists boolean)
 LANGUAGE plpgsql
AS $function$
DECLARE
  existing_patient_id TEXT;
  existing_appointment_count INT;
BEGIN
  SELECT id INTO existing_patient_id
  FROM "Patient"
  WHERE "accountNumber" = p_account_number
  LIMIT 1;

  IF existing_patient_id IS NULL THEN
    INSERT INTO "Patient" (
      "id", "accountNumber", "firstName", "lastName", "fullName", "dateOfBirth",
      "email", "homePhone", "cellPhone", "workPhone", "createdAt", "updatedAt"
    )
    VALUES (
      gen_random_uuid(), p_account_number, p_first_name, p_last_name, p_full_name,
      p_dob, p_email, p_home_phone, p_cell_phone, p_work_phone, now(), now()
    )
    RETURNING id INTO existing_patient_id;
  ELSE
    UPDATE "Patient"
    SET
      "email" = COALESCE(NULLIF(p_email, ''), "email"),
      "homePhone" = COALESCE(NULLIF(p_home_phone, ''), "homePhone"),
      "cellPhone" = COALESCE(NULLIF(p_cell_phone, ''), "cellPhone"),
      "workPhone" = COALESCE(NULLIF(p_work_phone, ''), "workPhone"),
      "updatedAt" = now()
    WHERE id = existing_patient_id;
  END IF;

  SELECT COUNT(*) INTO existing_appointment_count
  FROM "Appointment"
  WHERE
    "patientId" = existing_patient_id AND
    "doctorId" = p_doctor_id AND
    "appointmentDate" = p_appointment_date AND
    "appointmentTime" = p_appointment_time;

  RETURN QUERY SELECT existing_patient_id, (existing_appointment_count > 0);
END;
$function$
;
