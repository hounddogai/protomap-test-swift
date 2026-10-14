import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRollingDispenseAgreementsForRule(_ items: [RollingDispenseAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveFormularyRulesFromAgreement(_ items: [RollingDispenseAgreement]) -> [FormularyRule] {
        var out: [FormularyRule] = []
        for item in items {
            let derived = newFormularyRule(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchFormularyRule(_ item: FormularyRule) -> String {
        return classifyDispenseCycle(item.netTotal())
    }
}
