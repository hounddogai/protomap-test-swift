import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptivePriorityAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-priority-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func adaptivePriorityAuditBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a adaptive priority audit code in its canonical APA- form.
    static func normalizeAdaptivePriorityAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("APA-") {
            return clean
        }
        return "APA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
