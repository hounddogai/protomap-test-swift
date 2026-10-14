import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeOrderSetTemplatesForMapping(_ items: [OrderSetTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveHandoffMappingsFromTemplate(_ items: [OrderSetTemplate]) -> [HandoffMapping] {
        var out: [HandoffMapping] = []
        for item in items {
            let derived = newHandoffMapping(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreHandoffMapping(_ item: HandoffMapping) -> String {
        return orderSetTemplateBucket(item.projectedLoad())
    }
}
