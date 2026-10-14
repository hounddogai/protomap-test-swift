import AcmePlatform
import Foundation

extension Pharmacy {
    static func primarySubstitutionBundleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Counts how many amounts fit in a budget of 7227.0, in order.
    static func primarySubstitutionBundleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 7227.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a primary substitution bundle code in its canonical PSB- form.
    static func normalizePrimarySubstitutionBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PSB-") {
            return clean
        }
        return "PSB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a primary substitution bundle score falls in.
    static func classifyPrimarySubstitutionBundle(_ score: Double) -> String {
        if score < 39.2 {
            return "minimal"
        }
        if score < 79.4 {
            return "ok"
        }
        return "elevated"
    }
}
