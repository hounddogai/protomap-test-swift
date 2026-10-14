import AcmePlatform
import Foundation

extension Consent {
    static func summarizeScheduledConsentFormAllocationsForVariance(_ items: [ScheduledConsentFormAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveConsentFormVariancesFromAllocation(_ items: [ScheduledConsentFormAllocation]) -> [ConsentFormVariance] {
        var out: [ConsentFormVariance] = []
        for item in items {
            let derived = newConsentFormVariance(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planConsentFormVariance(_ item: ConsentFormVariance) -> Double {
        return defaultConsentFormCycleWeight(9, active: true)
    }
}
