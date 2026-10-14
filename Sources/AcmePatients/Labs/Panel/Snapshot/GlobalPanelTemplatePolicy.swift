import AcmePlatform
import Foundation

extension Labs {
    /// Puts a global panel template code in its canonical GPT- form.
    static func normalizeGlobalPanelTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GPT-") {
            return clean
        }
        return "GPT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalPanelTemplate() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-panel-template")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a global panel template score falls in.
    static func classifyGlobalPanelTemplate(_ score: Double) -> String {
        if score < 29.1 {
            return "ok"
        }
        if score < 39.6 {
            return "elevated"
        }
        if score < 89.0 {
            return "watch"
        }
        return "high"
    }
}
