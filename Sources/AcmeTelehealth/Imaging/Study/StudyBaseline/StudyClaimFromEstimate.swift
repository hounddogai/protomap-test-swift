import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeTieredWorklistEstimatesForClaim(_ items: [TieredWorklistEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveStudyClaimsFromEstimate(_ items: [TieredWorklistEstimate]) -> [StudyClaim] {
        var out: [StudyClaim] = []
        for item in items {
            let derived = newStudyClaim(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectStudyClaim(_ item: StudyClaim) -> String {
        return classifyTieredWorklistEstimate(item.netVolume())
    }
}
