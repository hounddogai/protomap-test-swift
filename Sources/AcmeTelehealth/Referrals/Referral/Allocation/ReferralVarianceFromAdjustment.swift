import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeClosureAdjustmentsForVariance(_ items: [ClosureAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveReferralVariancesFromAdjustment(_ items: [ClosureAdjustment]) -> [ReferralVariance] {
        var out: [ReferralVariance] = []
        for item in items {
            let derived = newReferralVariance(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveReferralVariance(_ item: ReferralVariance) -> String {
        return defaultClosureBundleBucket(item.weightedLoad())
    }
}
