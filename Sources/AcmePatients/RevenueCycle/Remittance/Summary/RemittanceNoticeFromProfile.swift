import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeLegacyClaimProfilesForNotice(_ items: [LegacyClaimProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRemittanceNoticesFromProfile(_ items: [LegacyClaimProfile]) -> [RemittanceNotice] {
        var out: [RemittanceNotice] = []
        for item in items {
            let derived = newRemittanceNotice(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitRemittanceNotice(_ item: RemittanceNotice) -> String {
        return legacyClaimProfileBucket(item.netTotal())
    }
}
