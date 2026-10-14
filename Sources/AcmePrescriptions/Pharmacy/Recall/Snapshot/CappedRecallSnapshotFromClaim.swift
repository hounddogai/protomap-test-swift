import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRollingSubstitutionClaimsForSnapshot(_ items: [RollingSubstitutionClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveCappedRecallSnapshotsFromClaim(_ items: [RollingSubstitutionClaim]) -> [CappedRecallSnapshot] {
        var out: [CappedRecallSnapshot] = []
        for item in items {
            let derived = newCappedRecallSnapshot(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignCappedRecallSnapshot(_ item: CappedRecallSnapshot) -> String {
        return classifyRollingSubstitutionClaim(item.effectiveValue())
    }
}
