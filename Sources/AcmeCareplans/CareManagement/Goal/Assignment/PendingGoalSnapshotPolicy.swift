import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a pending goal snapshot code in its canonical PGS- form.
    static func normalizePendingGoalSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PGS-") {
            return clean
        }
        return "PGS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func pendingGoalSnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func pendingGoalSnapshotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    static func pendingGoalSnapshotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.62
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
