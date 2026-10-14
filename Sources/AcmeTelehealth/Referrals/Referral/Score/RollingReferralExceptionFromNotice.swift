import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSeasonalSlotNoticesForException(_ items: [SeasonalSlotNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveRollingReferralExceptionsFromNotice(_ items: [SeasonalSlotNotice]) -> [RollingReferralException] {
        var out: [RollingReferralException] = []
        for item in items {
            let derived = newRollingReferralException(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeRollingReferralException(_ item: RollingReferralException) -> String {
        return classifyStrictSlotRecord(item.adjustedExposure())
    }
}
