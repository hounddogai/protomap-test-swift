import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeBatchedClaimAgreementsForSlot(_ items: [BatchedClaimAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveLenientRemittanceSlotsFromAgreement(_ items: [BatchedClaimAgreement]) -> [LenientRemittanceSlot] {
        var out: [LenientRemittanceSlot] = []
        for item in items {
            let derived = newLenientRemittanceSlot(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeLenientRemittanceSlot(_ item: LenientRemittanceSlot) -> String {
        return classifyClaimMetric(item.measuredValue())
    }
}
