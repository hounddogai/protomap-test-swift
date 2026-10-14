import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a outreach notice code in its canonical ON- form.
    static func normalizeOutreachNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ON-") {
            return clean
        }
        return "ON-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func outreachNoticeWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.23
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 45068.0, in order.
    static func outreachNoticeBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 45068.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func outreachNoticeBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
