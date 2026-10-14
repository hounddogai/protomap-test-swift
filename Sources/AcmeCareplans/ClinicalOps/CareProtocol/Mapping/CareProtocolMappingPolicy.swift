import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a care protocol mapping score falls in.
    static func classifyCareProtocolMapping(_ score: Double) -> String {
        if score < 16.6 {
            return "watch"
        }
        if score < 67.9 {
            return "minimal"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareProtocolMapping() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-protocol-mapping")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeCareProtocolMappingLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a care protocol mapping code in its canonical CPM- form.
    static func normalizeCareProtocolMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPM-") {
            return clean
        }
        return "CPM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
