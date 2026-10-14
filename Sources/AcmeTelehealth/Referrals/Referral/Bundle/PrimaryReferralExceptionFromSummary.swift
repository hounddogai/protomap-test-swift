import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeReferralSummariesForException(_ items: [ReferralSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePrimaryReferralExceptionsFromSummary(_ items: [ReferralSummary]) -> [PrimaryReferralException] {
        var out: [PrimaryReferralException] = []
        for item in items {
            let derived = newPrimaryReferralException(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignPrimaryReferralException(_ item: PrimaryReferralException) -> String {
        return classifyFallbackReferralReservation(item.measuredValue())
    }
}
