import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a legacy reference range manifest score falls in.
    static func classifyLegacyReferenceRangeManifest(_ score: Double) -> String {
        if score < 11.8 {
            return "medium"
        }
        if score < 34.1 {
            return "elevated"
        }
        if score < 56.3 {
            return "low"
        }
        if score < 92.4 {
            return "high"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyReferenceRangeManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-reference-range-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a legacy reference range manifest code in its canonical LRRM- form.
    static func normalizeLegacyReferenceRangeManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LRRM-") {
            return clean
        }
        return "LRRM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
