import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a capped bed board record code in its canonical CBBR- form.
    static func normalizeCappedBedBoardRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CBBR-") {
            return clean
        }
        return "CBBR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func cappedBedBoardRecordBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func cappedBedBoardRecordWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.89
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
