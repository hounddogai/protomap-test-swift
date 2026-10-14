import AcmePlatform
import Foundation

extension Imaging {
    static func legacyCareProtocolThresholdSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Puts a legacy care protocol threshold code in its canonical LCPT- form.
    static func normalizeLegacyCareProtocolThresholdCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LCPT-") {
            return clean
        }
        return "LCPT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyCareProtocolThreshold() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-care-protocol-threshold")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
