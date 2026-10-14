import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeCareProtocolSlotsForAgreement(_ items: [CareProtocolSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveFallbackWorklistAgreementsFromSlot(_ items: [CareProtocolSlot]) -> [FallbackWorklistAgreement] {
        var out: [FallbackWorklistAgreement] = []
        for item in items {
            let derived = newFallbackWorklistAgreement(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleFallbackWorklistAgreement(_ item: FallbackWorklistAgreement) -> String {
        return careProtocolSlotBucket(item.weightedLoad())
    }
}
