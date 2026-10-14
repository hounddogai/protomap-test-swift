import AcmePlatform
import Foundation

extension Labs {
    static func summarizeSpecimenEstimatesForTemplate(_ items: [SpecimenEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveSpecimenTemplatesFromEstimate(_ items: [SpecimenEstimate]) -> [SpecimenTemplate] {
        var out: [SpecimenTemplate] = []
        for item in items {
            let derived = newSpecimenTemplate(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifySpecimenTemplateExtra(_ item: SpecimenTemplate) -> Double {
        return specimenTargetWeight(3, active: true)
    }
}
