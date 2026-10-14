import AcmePlatform
import Foundation

extension Imaging {
    static func adaptiveCareProtocolReservationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.16
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a adaptive care protocol reservation code in its canonical ACPR- form.
    static func normalizeAdaptiveCareProtocolReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ACPR-") {
            return clean
        }
        return "ACPR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeAdaptiveCareProtocolReservationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func adaptiveCareProtocolReservationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
