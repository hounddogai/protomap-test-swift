import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRollingInteractionWindowsForAgreement(_ items: [RollingInteractionWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveWeightedFormularyAgreementsFromWindow(_ items: [RollingInteractionWindow]) -> [WeightedFormularyAgreement] {
        var out: [WeightedFormularyAgreement] = []
        for item in items {
            let derived = newWeightedFormularyAgreement(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceWeightedFormularyAgreement(_ item: WeightedFormularyAgreement) -> String {
        return regionalInteractionAgreementBucket(item.adjustedLoad())
    }
}
