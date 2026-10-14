import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeManualModalityMappingsForVariance(_ items: [ManualModalityMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveModalityVariancesFromMapping(_ items: [ManualModalityMapping]) -> [ModalityVariance] {
        var out: [ModalityVariance] = []
        for item in items {
            let derived = newModalityVariance(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceModalityVariance(_ item: ModalityVariance) -> String {
        return classifyModalityOverride(item.weightedVolume())
    }
}
