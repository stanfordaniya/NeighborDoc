import Foundation

class InputValidator {
    static let shared = InputValidator()
    
    private init() {}
    
    // MARK: - Input Sanitization
    
    func sanitizeString(_ input: String) -> String {
        return input.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#x27;")
    }
    
    func sanitizeSearchQuery(_ query: String) -> String {
        let sanitized = sanitizeString(query)
        // Remove potential SQL injection patterns
        return sanitized.replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: ";", with: "")
            .replacingOccurrences(of: "--", with: "")
    }
    
    // MARK: - Validation Functions
    
    func isValidName(_ name: String) -> Bool {
        let nameRegex = "^[a-zA-Z\\s\\-\\.']{2,50}$"
        let namePredicate = NSPredicate(format: "SELF MATCHES %@", nameRegex)
        return namePredicate.evaluate(with: name)
    }
    
    func isValidPhoneNumber(_ phone: String) -> Bool {
        let phoneRegex = "^[0-9\\-\\(\\)\\s\\+]{10,15}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phone)
    }
    
    func isValidZipCode(_ zipCode: String) -> Bool {
        let zipRegex = "^[0-9]{5}(-[0-9]{4})?$"
        let zipPredicate = NSPredicate(format: "SELF MATCHES %@", zipRegex)
        return zipPredicate.evaluate(with: zipCode)
    }
    
    func isValidState(_ state: String) -> Bool {
        let validStates = ["AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
                          "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD",
                          "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ",
                          "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC",
                          "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"]
        return validStates.contains(state.uppercased())
    }
    
    func isValidSpecialty(_ specialty: String) -> Bool {
        let validSpecialties = ["Pediatrics", "Dermatology", "Cardiology", "Orthopedics",
                               "Neurology", "Family Medicine", "Oncology", "Psychiatry",
                               "Emergency Medicine", "Obstetrics", "Internal Medicine",
                               "Gynecology", "Urology", "Anesthesiology", "Radiology"]
        return validSpecialties.contains(specialty)
    }
    
    func isValidRaceEthnicity(_ race: String) -> Bool {
        let validRaces = ["Asian", "Black", "Hispanic", "White", "South Asian", "Native American",
                         "Pacific Islander", "Mixed", "Other"]
        return validRaces.contains(race)
    }
    
    // MARK: - Length Validation
    
    func isValidLength(_ input: String, min: Int, max: Int) -> Bool {
        return input.count >= min && input.count <= max
    }
    
    // MARK: - XSS Prevention
    
    func containsXSSPatterns(_ input: String) -> Bool {
        let xssPatterns = [
            "<script", "</script>", "javascript:", "onload=", "onerror=",
            "onclick=", "onmouseover=", "onfocus=", "onblur=",
            "eval(", "alert(", "document.cookie", "window.location"
        ]
        
        let lowercasedInput = input.lowercased()
        return xssPatterns.contains { lowercasedInput.contains($0) }
    }
    
    // MARK: - SQL Injection Prevention
    
    func containsSQLInjectionPatterns(_ input: String) -> Bool {
        let sqlPatterns = [
            "union", "select", "insert", "update", "delete", "drop", "create",
            "alter", "exec", "execute", "sp_", "xp_", "/*", "*/", "--",
            "or 1=1", "and 1=1", "' or '1'='1", "\" or \"1\"=\"1"
        ]
        
        let lowercasedInput = input.lowercased()
        return sqlPatterns.contains { lowercasedInput.contains($0) }
    }
}
