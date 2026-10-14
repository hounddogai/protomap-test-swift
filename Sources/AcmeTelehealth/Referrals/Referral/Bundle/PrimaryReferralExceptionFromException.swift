import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeDefaultSlotExceptionsForException(_ items: [DefaultSlotException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func derivePrimaryReferralExceptionsFromException(_ items: [DefaultSlotException]) -> [PrimaryReferralException] {
        var out: [PrimaryReferralException] = []
        for item in items {
            let derived = newPrimaryReferralException(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignPrimaryReferralExceptionExtra(_ item: PrimaryReferralException) -> String {
        return classifyDefaultSlotException(item.measuredValue())
    }
}
