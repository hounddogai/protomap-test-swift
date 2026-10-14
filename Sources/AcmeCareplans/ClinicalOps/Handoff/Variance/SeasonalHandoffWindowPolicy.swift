import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalHandoffWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-handoff-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a seasonal handoff window code in its canonical SHW- form.
    static func normalizeSeasonalHandoffWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SHW-") {
            return clean
        }
        return "SHW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
