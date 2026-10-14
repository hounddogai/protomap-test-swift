import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeDefaultRecallEntriesForRule(_ items: [DefaultRecallEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFormularyRulesFromEntry(_ items: [DefaultRecallEntry]) -> [FormularyRule] {
        var out: [FormularyRule] = []
        for item in items {
            let derived = newFormularyRule(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveFormularyRule(_ item: FormularyRule) -> String {
        return recallSnapshotBucket(item.netTotal())
    }
}
