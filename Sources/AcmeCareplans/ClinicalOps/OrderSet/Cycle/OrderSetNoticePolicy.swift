import AcmePlatform
import Foundation

extension ClinicalOps {
    static func mergeOrderSetNoticeLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 63161.0, in order.
    static func orderSetNoticeBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 63161.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func orderSetNoticeBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Puts a order set notice code in its canonical OSN- form.
    static func normalizeOrderSetNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OSN-") {
            return clean
        }
        return "OSN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
