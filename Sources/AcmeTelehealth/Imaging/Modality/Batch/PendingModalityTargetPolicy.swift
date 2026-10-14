import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a pending modality target code in its canonical PMT- form.
    static func normalizePendingModalityTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PMT-") {
            return clean
        }
        return "PMT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func pendingModalityTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.92
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 67198.0, in order.
    static func pendingModalityTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 67198.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
