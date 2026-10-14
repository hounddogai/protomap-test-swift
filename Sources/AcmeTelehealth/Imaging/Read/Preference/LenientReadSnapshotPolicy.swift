import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a lenient read snapshot code in its canonical LRS- form.
    static func normalizeLenientReadSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LRS-") {
            return clean
        }
        return "LRS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 50027.0, in order.
    static func lenientReadSnapshotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 50027.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeLenientReadSnapshotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func lenientReadSnapshotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.56
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
