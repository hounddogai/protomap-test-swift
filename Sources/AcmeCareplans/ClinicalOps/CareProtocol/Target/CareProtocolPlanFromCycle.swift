import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeOrderSetCyclesForPlan(_ items: [OrderSetCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveCareProtocolPlansFromCycle(_ items: [OrderSetCycle]) -> [CareProtocolPlan] {
        var out: [CareProtocolPlan] = []
        for item in items {
            let derived = newCareProtocolPlan(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveCareProtocolPlan(_ item: CareProtocolPlan) -> String {
        return normalizeOrderSetSnapshotCode(item.code)
    }
}
