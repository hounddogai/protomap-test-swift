import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeInteractionWindowsForAudit(_ items: [InteractionWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveFormularyAuditsFromWindow(_ items: [InteractionWindow]) -> [FormularyAudit] {
        var out: [FormularyAudit] = []
        for item in items {
            let derived = newFormularyAudit(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreFormularyAudit(_ item: FormularyAudit) -> Double {
        return interactionWindowWeight(1, active: true)
    }
}
