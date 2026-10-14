import AcmePlatform
import Foundation

extension Staffing {
    static func manualCredentialWindowBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Counts how many amounts fit in a budget of 98218.0, in order.
    static func manualCredentialWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 98218.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a manual credential window code in its canonical MCW- form.
    static func normalizeManualCredentialWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MCW-") {
            return clean
        }
        return "MCW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a manual credential window score falls in.
    static func classifyManualCredentialWindow(_ score: Double) -> String {
        if score < 48.4 {
            return "critical"
        }
        if score < 55.9 {
            return "low"
        }
        if score < 59.3 {
            return "ok"
        }
        if score < 79.0 {
            return "high"
        }
        return "watch"
    }
}
