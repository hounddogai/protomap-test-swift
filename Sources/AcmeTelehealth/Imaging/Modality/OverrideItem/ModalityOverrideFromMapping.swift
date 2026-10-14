import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeSeasonalPriorityMappingsForOverride(_ items: [SeasonalPriorityMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveModalityOverridesFromMapping(_ items: [SeasonalPriorityMapping]) -> [ModalityOverride] {
        var out: [ModalityOverride] = []
        for item in items {
            let derived = newModalityOverride(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreModalityOverride(_ item: ModalityOverride) -> String {
        return normalizePriorityQuotaCode(item.code)
    }
}
