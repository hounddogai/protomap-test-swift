import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 67811.0, in order.
    static func fallbackProgramNoticeBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 67811.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a fallback program notice code in its canonical FPN- form.
    static func normalizeFallbackProgramNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FPN-") {
            return clean
        }
        return "FPN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func fallbackProgramNoticeWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.82
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
