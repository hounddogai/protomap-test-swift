import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a tiered remittance request score falls in.
    static func classifyTieredRemittanceRequest(_ score: Double) -> String {
        if score < 18.4 {
            return "ok"
        }
        if score < 19.2 {
            return "elevated"
        }
        if score < 19.6 {
            return "low"
        }
        if score < 66.1 {
            return "medium"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 27115.0, in order.
    static func tieredRemittanceRequestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 27115.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a tiered remittance request code in its canonical TRR- form.
    static func normalizeTieredRemittanceRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TRR-") {
            return clean
        }
        return "TRR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
