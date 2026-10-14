import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCareProtocolCyclesForNotice(_ items: [CareProtocolCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveHandoffNoticesFromCycle(_ items: [CareProtocolCycle]) -> [HandoffNotice] {
        var out: [HandoffNotice] = []
        for item in items {
            let derived = newHandoffNotice(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeHandoffNotice(_ item: HandoffNotice) -> Double {
        return careProtocolCycleWeight(1, active: true)
    }
}
