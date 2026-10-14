import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 38940.0, in order.
    static func proxyScheduleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 38940.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a proxy schedule score falls in.
    static func classifyProxySchedule(_ score: Double) -> String {
        if score < 17.0 {
            return "elevated"
        }
        if score < 32.7 {
            return "ok"
        }
        if score < 76.2 {
            return "high"
        }
        return "critical"
    }

    /// Puts a proxy schedule code in its canonical PS- form.
    static func normalizeProxyScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PS-") {
            return clean
        }
        return "PS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
