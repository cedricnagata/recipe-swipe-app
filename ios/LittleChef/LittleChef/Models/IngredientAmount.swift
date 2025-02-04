import Foundation

struct IngredientAmount {
    let amount: Float?
    let unit: String?
    let originalText: String
    
    init(from text: String) {
        self.originalText = text
        
        // Convert the text into components
        let components = text.trimmingCharacters(in: .whitespaces).components(separatedBy: " ")
        
        // Try to parse the first component as a number
        if let first = components.first,
           let number = Float(first.replacingOccurrences(of: ",", with: ".")) {
            self.amount = number
            // If there's more components, the second one is likely the unit
            if components.count > 1 {
                self.unit = components[1]
            } else {
                self.unit = nil
            }
        } else {
            self.amount = nil
            self.unit = nil
        }
    }
    
    func scaled(by factor: Float) -> String {
        guard let amount = amount else { return originalText }
        
        let scaledAmount = amount * factor
        if let unit = unit {
            return String(format: "%.1f %@ %@", 
                         scaledAmount, 
                         unit,
                         originalText.components(separatedBy: " ").dropFirst(2).joined(separator: " "))
        } else {
            return String(format: "%.1f %@", 
                         scaledAmount,
                         originalText.components(separatedBy: " ").dropFirst().joined(separator: " "))
        }
    }
}

extension IngredientAmount {
    static func parseAndScale(_ originalAmount: String, by factor: Float) -> String {
        let amount = IngredientAmount(from: originalAmount)
        return amount.scaled(by: factor)
    }
}