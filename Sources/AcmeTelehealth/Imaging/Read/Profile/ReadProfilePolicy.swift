import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeReadProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("read-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a read profile code in its canonical RP- form.
    static func normalizeReadProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RP-") {
            return clean
        }
        return "RP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
