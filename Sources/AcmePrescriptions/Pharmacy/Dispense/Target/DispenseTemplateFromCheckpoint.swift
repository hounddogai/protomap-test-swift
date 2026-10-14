import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFormularyCheckpointsForTemplate(_ items: [FormularyCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveDispenseTemplatesFromCheckpoint(_ items: [FormularyCheckpoint]) -> [DispenseTemplate] {
        var out: [DispenseTemplate] = []
        for item in items {
            let derived = newDispenseTemplate(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateDispenseTemplate(_ item: DispenseTemplate) -> String {
        return classifyFormularyCheckpoint(item.weightedLoad())
    }
}
