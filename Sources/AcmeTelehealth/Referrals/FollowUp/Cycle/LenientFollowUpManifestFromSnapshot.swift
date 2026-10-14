import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeLenientEligibilitySnapshotsForManifest(_ items: [LenientEligibilitySnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveLenientFollowUpManifestsFromSnapshot(_ items: [LenientEligibilitySnapshot]) -> [LenientFollowUpManifest] {
        var out: [LenientFollowUpManifest] = []
        for item in items {
            let derived = newLenientFollowUpManifest(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceLenientFollowUpManifest(_ item: LenientFollowUpManifest) -> String {
        return eligibilityPolicyBucket(item.projectedVolume())
    }
}
