import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFormularyGroupsForRollup(_ items: [FormularyGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveRecallRollupsFromGroup(_ items: [FormularyGroup]) -> [RecallRollup] {
        var out: [RecallRollup] = []
        for item in items {
            let derived = newRecallRollup(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectRecallRollup(_ item: RecallRollup) -> String {
        return classifyFormularyVariance(item.measuredValue())
    }
}
