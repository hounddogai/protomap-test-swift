import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 84765.0, in order.
    static func bedBoardSnapshotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 84765.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a bed board snapshot score falls in.
    static func classifyBedBoardSnapshot(_ score: Double) -> String {
        if score < 1.7 {
            return "medium"
        }
        if score < 30.1 {
            return "critical"
        }
        if score < 48.3 {
            return "ok"
        }
        if score < 91.1 {
            return "elevated"
        }
        return "minimal"
    }

    /// Puts a bed board snapshot code in its canonical BBS- form.
    static func normalizeBedBoardSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BBS-") {
            return clean
        }
        return "BBS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func bedBoardSnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
