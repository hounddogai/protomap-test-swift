import AcmePlatform
import Foundation

extension Consent {
    /// Puts a capped revocation bundle code in its canonical CRB- form.
    static func normalizeCappedRevocationBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CRB-") {
            return clean
        }
        return "CRB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a capped revocation bundle score falls in.
    static func classifyCappedRevocationBundle(_ score: Double) -> String {
        if score < 10.6 {
            return "low"
        }
        if score < 61.9 {
            return "high"
        }
        if score < 89.9 {
            return "minimal"
        }
        return "ok"
    }

    /// Counts how many amounts fit in a budget of 82278.0, in order.
    static func cappedRevocationBundleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 82278.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
