import AcmePlatform
import Foundation

extension Staffing {
    static func pendingFloatPoolTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Puts a pending float pool target code in its canonical PFPT- form.
    static func normalizePendingFloatPoolTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PFPT-") {
            return clean
        }
        return "PFPT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func pendingFloatPoolTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.28
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
