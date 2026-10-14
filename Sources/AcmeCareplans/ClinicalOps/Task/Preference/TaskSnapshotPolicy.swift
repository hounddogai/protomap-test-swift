import AcmePlatform
import Foundation

extension ClinicalOps {
    static func taskSnapshotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.85
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func taskSnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a task snapshot code in its canonical TS- form.
    static func normalizeTaskSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TS-") {
            return clean
        }
        return "TS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func taskSnapshotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }
}
