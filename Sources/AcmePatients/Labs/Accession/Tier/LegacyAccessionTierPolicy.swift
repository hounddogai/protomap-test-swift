import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyAccessionTier() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-accession-tier")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a legacy accession tier code in its canonical LAT- form.
    static func normalizeLegacyAccessionTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LAT-") {
            return clean
        }
        return "LAT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeLegacyAccessionTierLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
