import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 13252.0, in order.
    static func closureNoticeBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 13252.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a closure notice code in its canonical CN- form.
    static func normalizeClosureNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CN-") {
            return clean
        }
        return "CN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
