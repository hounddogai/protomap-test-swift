import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a strict inventory audit code in its canonical SIA- form.
    static func normalizeStrictInventoryAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SIA-") {
            return clean
        }
        return "SIA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func strictInventoryAuditSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    static func strictInventoryAuditWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.78
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func strictInventoryAuditBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
