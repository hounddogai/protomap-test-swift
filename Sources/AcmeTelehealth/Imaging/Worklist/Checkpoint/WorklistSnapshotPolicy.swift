import AcmePlatform
import Foundation

extension Imaging {
    static func worklistSnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Counts how many amounts fit in a budget of 4643.0, in order.
    static func worklistSnapshotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 4643.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a worklist snapshot code in its canonical WS- form.
    static func normalizeWorklistSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WS-") {
            return clean
        }
        return "WS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
