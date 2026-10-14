import AcmePlatform
import Foundation

extension Labs {
    /// Puts a global specimen slot code in its canonical GSS- form.
    static func normalizeGlobalSpecimenSlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GSS-") {
            return clean
        }
        return "GSS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func globalSpecimenSlotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalSpecimenSlot() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-specimen-slot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func globalSpecimenSlotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }
}
