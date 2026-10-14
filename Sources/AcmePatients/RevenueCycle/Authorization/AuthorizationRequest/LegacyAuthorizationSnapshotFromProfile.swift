import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeScheduledStatementProfilesForSnapshot(_ items: [ScheduledStatementProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveLegacyAuthorizationSnapshotsFromProfile(_ items: [ScheduledStatementProfile]) -> [LegacyAuthorizationSnapshot] {
        var out: [LegacyAuthorizationSnapshot] = []
        for item in items {
            let derived = newLegacyAuthorizationSnapshot(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveLegacyAuthorizationSnapshot(_ item: LegacyAuthorizationSnapshot) -> String {
        return classifyScheduledStatementProfile(item.weightedLoad())
    }
}
