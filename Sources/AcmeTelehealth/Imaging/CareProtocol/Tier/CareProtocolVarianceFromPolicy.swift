import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePendingModalityPoliciesForVariance(_ items: [PendingModalityPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveCareProtocolVariancesFromPolicy(_ items: [PendingModalityPolicy]) -> [CareProtocolVariance] {
        var out: [CareProtocolVariance] = []
        for item in items {
            let derived = newCareProtocolVariance(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveCareProtocolVariance(_ item: CareProtocolVariance) -> String {
        return manualModalitySummaryBucket(item.adjustedTotal())
    }
}
