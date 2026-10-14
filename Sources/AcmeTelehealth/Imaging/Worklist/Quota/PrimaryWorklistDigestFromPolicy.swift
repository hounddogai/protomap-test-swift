import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeCareProtocolPoliciesForDigest(_ items: [CareProtocolPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func derivePrimaryWorklistDigestsFromPolicy(_ items: [CareProtocolPolicy]) -> [PrimaryWorklistDigest] {
        var out: [PrimaryWorklistDigest] = []
        for item in items {
            let derived = newPrimaryWorklistDigest(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planPrimaryWorklistDigest(_ item: PrimaryWorklistDigest) -> String {
        return classifyCareProtocolOverride(item.effectiveVolume())
    }
}
