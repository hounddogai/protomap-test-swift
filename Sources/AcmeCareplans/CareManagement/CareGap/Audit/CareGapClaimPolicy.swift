import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareGapClaim() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-gap-claim")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeCareGapClaimLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a care gap claim score falls in.
    static func classifyCareGapClaim(_ score: Double) -> String {
        if score < 27.4 {
            return "elevated"
        }
        if score < 77.4 {
            return "critical"
        }
        if score < 79.3 {
            return "high"
        }
        if score < 86.2 {
            return "low"
        }
        return "medium"
    }

    /// Puts a care gap claim code in its canonical CGC- form.
    static func normalizeCareGapClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CGC-") {
            return clean
        }
        return "CGC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
