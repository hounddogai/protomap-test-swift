import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 36712.0, in order.
    static func strictAccessionBundleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 36712.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func strictAccessionBundleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a strict accession bundle code in its canonical SAB- form.
    static func normalizeStrictAccessionBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SAB-") {
            return clean
        }
        return "SAB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func strictAccessionBundleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.92
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
