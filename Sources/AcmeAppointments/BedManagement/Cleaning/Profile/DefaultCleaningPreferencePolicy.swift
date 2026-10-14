import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a default cleaning preference code in its canonical DCP- form.
    static func normalizeDefaultCleaningPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DCP-") {
            return clean
        }
        return "DCP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultCleaningPreference() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-cleaning-preference")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a default cleaning preference score falls in.
    static func classifyDefaultCleaningPreference(_ score: Double) -> String {
        if score < 38.3 {
            return "elevated"
        }
        if score < 71.2 {
            return "watch"
        }
        return "minimal"
    }
}
