import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 38279.0, in order.
    static func accessionTemplateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 38279.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a accession template code in its canonical AT- form.
    static func normalizeAccessionTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AT-") {
            return clean
        }
        return "AT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func accessionTemplateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.95
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a accession template score falls in.
    static func classifyAccessionTemplate(_ score: Double) -> String {
        if score < 78.4 {
            return "watch"
        }
        if score < 95.4 {
            return "low"
        }
        return "minimal"
    }
}
