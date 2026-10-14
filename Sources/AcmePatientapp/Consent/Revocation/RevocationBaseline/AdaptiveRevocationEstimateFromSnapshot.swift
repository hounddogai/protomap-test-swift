import AcmePlatform
import Foundation

extension Consent {
    static func summarizePrimaryConsentFormSnapshotsForEstimate(_ items: [PrimaryConsentFormSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveAdaptiveRevocationEstimatesFromSnapshot(_ items: [PrimaryConsentFormSnapshot]) -> [AdaptiveRevocationEstimate] {
        var out: [AdaptiveRevocationEstimate] = []
        for item in items {
            let derived = newAdaptiveRevocationEstimate(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchAdaptiveRevocationEstimate(_ item: AdaptiveRevocationEstimate) -> String {
        return classifyStrictConsentFormOverride(item.weightedExposure())
    }
}
