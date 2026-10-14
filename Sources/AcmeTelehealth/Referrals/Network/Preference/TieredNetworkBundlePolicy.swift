import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 89620.0, in order.
    static func tieredNetworkBundleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 89620.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func tieredNetworkBundleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Puts a tiered network bundle code in its canonical TNB- form.
    static func normalizeTieredNetworkBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TNB-") {
            return clean
        }
        return "TNB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
