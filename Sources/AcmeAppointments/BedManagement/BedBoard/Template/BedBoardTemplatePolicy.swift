import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 30386.0, in order.
    static func bedBoardTemplateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 30386.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a bed board template score falls in.
    static func classifyBedBoardTemplate(_ score: Double) -> String {
        if score < 56.8 {
            return "low"
        }
        if score < 89.6 {
            return "watch"
        }
        if score < 94.3 {
            return "high"
        }
        return "medium"
    }

    /// Puts a bed board template code in its canonical BBT- form.
    static func normalizeBedBoardTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BBT-") {
            return clean
        }
        return "BBT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
