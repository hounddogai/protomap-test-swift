import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 90562.0, in order.
    static func defaultCourierPreferenceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 90562.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func defaultCourierPreferenceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Puts a default courier preference code in its canonical DCP- form.
    static func normalizeDefaultCourierPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DCP-") {
            return clean
        }
        return "DCP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
