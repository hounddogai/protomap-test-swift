import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a care protocol manifest code in its canonical CPM- form.
    static func normalizeCareProtocolManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPM-") {
            return clean
        }
        return "CPM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareProtocolManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-protocol-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a care protocol manifest score falls in.
    static func classifyCareProtocolManifest(_ score: Double) -> String {
        if score < 6.0 {
            return "elevated"
        }
        if score < 11.3 {
            return "critical"
        }
        if score < 60.0 {
            return "minimal"
        }
        if score < 87.3 {
            return "low"
        }
        return "medium"
    }

    static func mergeCareProtocolManifestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
