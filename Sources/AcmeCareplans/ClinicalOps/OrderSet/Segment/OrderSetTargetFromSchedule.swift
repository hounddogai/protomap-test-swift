import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCareProtocolSchedulesForTarget(_ items: [CareProtocolSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveOrderSetTargetsFromSchedule(_ items: [CareProtocolSchedule]) -> [OrderSetTarget] {
        var out: [OrderSetTarget] = []
        for item in items {
            let derived = newOrderSetTarget(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankOrderSetTarget(_ item: OrderSetTarget) -> String {
        return classifyCareProtocolSchedule(item.effectiveValue())
    }
}
