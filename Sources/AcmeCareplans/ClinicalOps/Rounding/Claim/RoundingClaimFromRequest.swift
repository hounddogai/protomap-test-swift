import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeManualCareProtocolRequestsForClaim(_ items: [ManualCareProtocolRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveRoundingClaimsFromRequest(_ items: [ManualCareProtocolRequest]) -> [RoundingClaim] {
        var out: [RoundingClaim] = []
        for item in items {
            let derived = newRoundingClaim(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func planRoundingClaim(_ item: RoundingClaim) -> Double {
        return manualCareProtocolRequestWeight(9, active: true)
    }
}
