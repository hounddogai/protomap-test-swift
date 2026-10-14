import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLenientConsentFormSnapshotsForScore(_ items: [LenientConsentFormSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveRegionalRevocationScoresFromSnapshot(_ items: [LenientConsentFormSnapshot]) -> [RegionalRevocationScore] {
        var out: [RegionalRevocationScore] = []
        for item in items {
            let derived = newRegionalRevocationScore(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankRegionalRevocationScore(_ item: RegionalRevocationScore) -> String {
        return lenientConsentFormSnapshotBucket(item.projectedValue())
    }
}
