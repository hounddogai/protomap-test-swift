import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLegacyRevocationBundlesForSlot(_ items: [LegacyRevocationBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveConsentFormSlotsFromBundle(_ items: [LegacyRevocationBundle]) -> [ConsentFormSlot] {
        var out: [ConsentFormSlot] = []
        for item in items {
            let derived = newConsentFormSlot(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceConsentFormSlot(_ item: ConsentFormSlot) -> String {
        return normalizeRevocationSnapshotCode(item.code)
    }
}
