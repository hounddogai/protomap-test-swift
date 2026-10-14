import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a regional priority target code in its canonical RPT- form.
    static func normalizeRegionalPriorityTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RPT-") {
            return clean
        }
        return "RPT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalPriorityTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-priority-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
