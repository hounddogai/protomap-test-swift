import AcmePlatform
import Foundation

extension Staffing {
    static func batchedOvertimeRollupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a batched overtime rollup code in its canonical BOR- form.
    static func normalizeBatchedOvertimeRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BOR-") {
            return clean
        }
        return "BOR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func batchedOvertimeRollupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.85
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
