import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLenientConsentFormBatchesForBudget(_ items: [LenientConsentFormBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveRegionalDisclosureBudgetsFromBatch(_ items: [LenientConsentFormBatch]) -> [RegionalDisclosureBudget] {
        var out: [RegionalDisclosureBudget] = []
        for item in items {
            let derived = newRegionalDisclosureBudget(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignRegionalDisclosureBudget(_ item: RegionalDisclosureBudget) -> Double {
        return lenientConsentFormBatchWeight(9, active: true)
    }
}
