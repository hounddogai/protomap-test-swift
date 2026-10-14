import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeLenientInteractionScheduleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a lenient interaction schedule code in its canonical LIS- form.
    static func normalizeLenientInteractionScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LIS-") {
            return clean
        }
        return "LIS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func lenientInteractionScheduleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientInteractionSchedule() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-interaction-schedule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
