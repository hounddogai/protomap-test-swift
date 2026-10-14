import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeCappedInteractionBaselinesForClaim(_ items: [CappedInteractionBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveGlobalSubstitutionClaimsFromBaseline(_ items: [CappedInteractionBaseline]) -> [GlobalSubstitutionClaim] {
        var out: [GlobalSubstitutionClaim] = []
        for item in items {
            let derived = newGlobalSubstitutionClaim(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreGlobalSubstitutionClaim(_ item: GlobalSubstitutionClaim) -> String {
        return normalizeStrictInteractionThresholdCode(item.code)
    }
}
