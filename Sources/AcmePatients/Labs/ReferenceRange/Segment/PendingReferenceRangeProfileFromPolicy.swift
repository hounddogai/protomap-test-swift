import AcmePlatform
import Foundation

extension Labs {
    static func summarizeDefaultSpecimenPoliciesForProfile(_ items: [DefaultSpecimenPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func derivePendingReferenceRangeProfilesFromPolicy(_ items: [DefaultSpecimenPolicy]) -> [PendingReferenceRangeProfile] {
        var out: [PendingReferenceRangeProfile] = []
        for item in items {
            let derived = newPendingReferenceRangeProfile(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectPendingReferenceRangeProfile(_ item: PendingReferenceRangeProfile) -> String {
        return rollingSpecimenProposalBucket(item.netVolume())
    }
}
