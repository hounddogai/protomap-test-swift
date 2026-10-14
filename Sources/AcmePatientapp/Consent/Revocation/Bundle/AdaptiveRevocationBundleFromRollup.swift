import AcmePlatform
import Foundation

extension Consent {
    static func summarizeConsentFormRollupsForBundle(_ items: [ConsentFormRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveAdaptiveRevocationBundlesFromRollup(_ items: [ConsentFormRollup]) -> [AdaptiveRevocationBundle] {
        var out: [AdaptiveRevocationBundle] = []
        for item in items {
            let derived = newAdaptiveRevocationBundle(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankAdaptiveRevocationBundle(_ item: AdaptiveRevocationBundle) -> String {
        return normalizeConsentFormSlotCode(item.code)
    }
}
