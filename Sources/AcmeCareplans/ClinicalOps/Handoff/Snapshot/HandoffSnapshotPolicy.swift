import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a handoff snapshot code in its canonical HS- form.
    static func normalizeHandoffSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("HS-") {
            return clean
        }
        return "HS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func handoffSnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeHandoffSnapshot() -> Int {
        let policy = Kit.Retry.defaultPolicy("handoff-snapshot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func handoffSnapshotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.67
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
