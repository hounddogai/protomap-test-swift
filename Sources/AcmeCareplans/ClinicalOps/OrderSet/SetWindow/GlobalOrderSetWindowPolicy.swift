import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalOrderSetWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-order-set-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func globalOrderSetWindowSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Puts a global order set window code in its canonical GOSW- form.
    static func normalizeGlobalOrderSetWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GOSW-") {
            return clean
        }
        return "GOSW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
