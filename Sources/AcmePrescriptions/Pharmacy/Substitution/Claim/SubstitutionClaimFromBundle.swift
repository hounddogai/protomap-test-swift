import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRecallBundlesForClaim(_ items: [RecallBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveSubstitutionClaimsFromBundle(_ items: [RecallBundle]) -> [SubstitutionClaim] {
        var out: [SubstitutionClaim] = []
        for item in items {
            let derived = newSubstitutionClaim(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateSubstitutionClaim(_ item: SubstitutionClaim) -> String {
        return legacyRecallSlotBucket(item.measuredValue())
    }
}
