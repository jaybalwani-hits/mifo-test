'use strict';

require('dotenv').config();
const path = require('path');
const XLSX = require('xlsx');
const connectWithConnector = require('./connect-connector');

async function importAppointmentsFromExcel(filePath) {
  const workbook = XLSX.readFile(filePath);
  const sheetName = workbook.SheetNames[0];
  const sheet = workbook.Sheets[sheetName];
  const rows = XLSX.utils.sheet_to_json(sheet, { raw: false, defval: null });

  console.log(`Read ${rows.length} rows from ${filePath}`);

  const knex = await connectWithConnector();

    try {
    await knex.raw('SELECT 1');
    console.log('Database connection successful.');

    for (const row of rows) {
        const doctor_id = row['doctor_id'];
        const date = row['date'];
        const start_time = row['start_time'];

        if (!doctor_id || !date || !start_time) {
        console.warn('Skipping incomplete row:', row);
        continue;
        }

        await knex.raw('CALL InsertIntoAppointment(?, ?, ?)', [
        doctor_id,
        date,
        start_time,
        ]);

        console.log(`Inserted: doctor_id=${doctor_id}, date=${date}, start_time=${start_time}`);
    }

    console.log('Import finished successfully.');
    } catch (error) {
    console.error('Error during import or connection:', error);
    } finally {
    await knex.destroy();
    }

}

const excelFilePath = path.resolve(__dirname, 'appointments.xlsx');

importAppointmentsFromExcel(excelFilePath);
