import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a fallback discharge plan allocation code in its canonical FDPA- form.
    static func normalizeFallbackDischargePlanAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FDPA-") {
            return clean
        }
        return "FDPA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackDischargePlanAllocation() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-discharge-plan-allocation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func fallbackDischargePlanAllocationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }
}
