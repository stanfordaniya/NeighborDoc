# Doctor Import Script Setup Guide

This guide will help you set up the Python script to bulk import doctors from a CSV file into Firebase Firestore.

## 📋 Prerequisites

- Python 3.7 or higher
- Firebase project with Firestore enabled
- CSV file with doctor data

## 🚀 Quick Setup

### Step 1: Install Dependencies

```bash
pip install -r requirements.txt
```

Or install individually:
```bash
pip install firebase-admin pandas
```

### Step 2: Prepare Your CSV File

Create a CSV file named `doctors.csv` with the following columns:

```csv
name,specialty,location,phone
Dr. Jane Doe,Pediatrics,Atlanta,404-123-4567
Dr. John Smith,Dermatology,New York,212-555-7890
Dr. Priya Patel,Cardiology,Chicago,312-555-1111
```

**Required columns:**
- `name`: Doctor's full name
- `specialty`: Medical specialty
- `location`: City/area
- `phone`: Phone number (used for duplicate checking)

### Step 3: Get Firebase Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click the ⚙️ gear icon → **Project Settings**
4. Go to **Service Accounts** tab
5. Click **Generate New Private Key**
6. Download the JSON file and rename it to `serviceAccountKey.json`
7. Place it in the same directory as your script

### Step 4: Run the Import Script

```bash
python import_doctors.py
```

## 📁 File Structure

Your directory should look like this:

```
your-project/
├── import_doctors.py
├── requirements.txt
├── doctors.csv
└── serviceAccountKey.json
```

## ✨ Features

- **Duplicate Prevention**: Automatically skips doctors with existing phone numbers
- **Error Handling**: Gracefully handles missing fields and connection issues
- **Progress Tracking**: Shows import progress and summary statistics
- **Data Validation**: Validates required fields before importing

## 📊 Expected Output

```
🏥 Doctor Import Script for Firebase Firestore
==================================================
Initializing Firebase connection...
Loading CSV file: doctors.csv
Found 3 records in CSV file
Imported: Dr. Jane Doe (Pediatrics)
Imported: Dr. John Smith (Dermatology)
Imported: Dr. Priya Patel (Cardiology)

==================================================
IMPORT SUMMARY
==================================================
✅ Successfully imported: 3 doctors
⏭️  Skipped (duplicates): 0 doctors
❌ Errors: 0 doctors
📊 Total processed: 3 doctors

🎉 Doctors imported successfully!
```

## 🔧 Troubleshooting

### Common Issues

1. **"Service account file not found"**
   - Make sure `serviceAccountKey.json` is in the same directory
   - Check the filename is exactly `serviceAccountKey.json`

2. **"CSV file not found"**
   - Ensure your CSV file is named `doctors.csv`
   - Check it's in the same directory as the script

3. **Firebase connection errors**
   - Verify your service account key is valid
   - Check your Firebase project has Firestore enabled
   - Ensure your internet connection is working

4. **Missing required fields**
   - The script will skip rows with missing required fields
   - Check your CSV has all required columns: name, specialty, location, phone

## 🔄 Future Updates

To update your doctor database:

1. Export your updated Excel/CSV file
2. Replace the existing `doctors.csv`
3. Run `python import_doctors.py` again

The script will automatically handle duplicates and only add new doctors.

## 🛠️ Customization

### Adding More Fields

To add more fields to your doctor records, modify the `validate_doctor_data` function in `import_doctors.py`:

```python
def validate_doctor_data(row: pd.Series) -> Optional[Dict[str, Any]]:
    # Add your new fields here
    doctor_data = {
        "name": str(row["name"]).strip(),
        "specialty": str(row["specialty"]).strip(),
        "location": str(row["location"]).strip(),
        "phone": str(row["phone"]).strip(),
        "email": str(row["email"]).strip(),  # New field
        "experience": int(row["experience"]) if not pd.isna(row["experience"]) else 0  # New field
    }
```

### Disabling Duplicate Checking

To allow duplicates, modify the main function call:

```python
import_doctors(CSV_FILE, SERVICE_ACCOUNT_FILE, skip_duplicates=False)
```

## 📞 Support

If you encounter any issues:

1. Check the error messages in the console
2. Verify your CSV format matches the requirements
3. Ensure your Firebase service account has proper permissions
4. Check that Firestore is enabled in your Firebase project
