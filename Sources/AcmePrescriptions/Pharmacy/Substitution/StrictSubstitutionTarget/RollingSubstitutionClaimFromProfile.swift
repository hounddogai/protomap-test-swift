import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeTieredSubstitutionProfilesForClaim(_ items: [TieredSubstitutionProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveRollingSubstitutionClaimsFromProfile(_ items: [TieredSubstitutionProfile]) -> [RollingSubstitutionClaim] {
        var out: [RollingSubstitutionClaim] = []
        for item in items {
            let derived = newRollingSubstitutionClaim(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankRollingSubstitutionClaim(_ item: RollingSubstitutionClaim) -> String {
        return classifyRollingSubstitutionDigest(item.adjustedVolume())
    }
}
