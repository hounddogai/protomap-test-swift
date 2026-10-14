import AcmePlatform
import Foundation

extension BedManagement {
    static func bedBoardCycleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 95583.0, in order.
    static func bedBoardCycleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 95583.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a bed board cycle code in its canonical BBC- form.
    static func normalizeBedBoardCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BBC-") {
            return clean
        }
        return "BBC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func bedBoardCycleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
