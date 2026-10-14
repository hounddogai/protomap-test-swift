import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGlobalOutreachThresholdsForClaim(_ items: [GlobalOutreachThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveCappedProgramClaimsFromThreshold(_ items: [GlobalOutreachThreshold]) -> [CappedProgramClaim] {
        var out: [CappedProgramClaim] = []
        for item in items {
            let derived = newCappedProgramClaim(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchCappedProgramClaim(_ item: CappedProgramClaim) -> String {
        return legacyOutreachDraftBucket(item.weightedExposure())
    }
}
