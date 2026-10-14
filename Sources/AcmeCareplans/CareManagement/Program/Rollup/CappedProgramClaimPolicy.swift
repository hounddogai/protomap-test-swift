import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 17197.0, in order.
    static func cappedProgramClaimBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 17197.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeCappedProgramClaimLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a capped program claim score falls in.
    static func classifyCappedProgramClaim(_ score: Double) -> String {
        if score < 26.1 {
            return "ok"
        }
        if score < 72.1 {
            return "elevated"
        }
        if score < 78.0 {
            return "critical"
        }
        return "high"
    }

    /// Puts a capped program claim code in its canonical CPC- form.
    static func normalizeCappedProgramClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPC-") {
            return clean
        }
        return "CPC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
