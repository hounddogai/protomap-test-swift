import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeReadAssignmentsForCycle(_ items: [ReadAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveModalityCyclesFromAssignment(_ items: [ReadAssignment]) -> [ModalityCycle] {
        var out: [ModalityCycle] = []
        for item in items {
            let derived = newModalityCycle(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignModalityCycle(_ item: ModalityCycle) -> Double {
        return readTemplateWeight(6, active: true)
    }
}
