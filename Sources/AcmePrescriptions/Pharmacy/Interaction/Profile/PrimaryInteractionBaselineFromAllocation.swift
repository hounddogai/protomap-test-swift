import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizePrimarySubstitutionAllocationsForBaseline(_ items: [PrimarySubstitutionAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func derivePrimaryInteractionBaselinesFromAllocation(_ items: [PrimarySubstitutionAllocation]) -> [PrimaryInteractionBaseline] {
        var out: [PrimaryInteractionBaseline] = []
        for item in items {
            let derived = newPrimaryInteractionBaseline(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func settlePrimaryInteractionBaseline(_ item: PrimaryInteractionBaseline) -> String {
        return normalizeGlobalSubstitutionTargetCode(item.code)
    }
}
