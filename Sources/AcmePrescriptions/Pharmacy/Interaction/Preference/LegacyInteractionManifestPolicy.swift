import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyInteractionManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-interaction-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeLegacyInteractionManifestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a legacy interaction manifest code in its canonical LIM- form.
    static func normalizeLegacyInteractionManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LIM-") {
            return clean
        }
        return "LIM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a legacy interaction manifest score falls in.
    static func classifyLegacyInteractionManifest(_ score: Double) -> String {
        if score < 16.6 {
            return "medium"
        }
        if score < 45.1 {
            return "minimal"
        }
        return "ok"
    }
}
