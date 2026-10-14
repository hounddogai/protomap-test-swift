import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeHandoffCycle() -> Int {
        let policy = Kit.Retry.defaultPolicy("handoff-cycle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a handoff cycle code in its canonical HC- form.
    static func normalizeHandoffCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("HC-") {
            return clean
        }
        return "HC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
