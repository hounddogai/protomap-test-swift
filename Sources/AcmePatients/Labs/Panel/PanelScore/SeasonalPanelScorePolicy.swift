import AcmePlatform
import Foundation

extension Labs {
    /// Puts a seasonal panel score code in its canonical SPS- form.
    static func normalizeSeasonalPanelScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SPS-") {
            return clean
        }
        return "SPS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalPanelScore() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-panel-score")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
