import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertPreferencesForPlan(_ items: [AlertPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveLenientTaskPlansFromPreference(_ items: [AlertPreference]) -> [LenientTaskPlan] {
        var out: [LenientTaskPlan] = []
        for item in items {
            let derived = newLenientTaskPlan(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileLenientTaskPlan(_ item: LenientTaskPlan) -> String {
        return defaultAlertAgreementBucket(item.measuredValue())
    }
}
