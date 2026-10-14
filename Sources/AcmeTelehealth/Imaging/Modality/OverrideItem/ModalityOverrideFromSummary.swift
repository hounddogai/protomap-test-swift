import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeCareProtocolSummariesForOverride(_ items: [CareProtocolSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveModalityOverridesFromSummary(_ items: [CareProtocolSummary]) -> [ModalityOverride] {
        var out: [ModalityOverride] = []
        for item in items {
            let derived = newModalityOverride(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceModalityOverride(_ item: ModalityOverride) -> Double {
        return scheduledCareProtocolMappingWeight(3, active: true)
    }
}
