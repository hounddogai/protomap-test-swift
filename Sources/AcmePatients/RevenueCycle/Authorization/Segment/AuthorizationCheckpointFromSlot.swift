import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeStrictAuthorizationSlotsForCheckpoint(_ items: [StrictAuthorizationSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAuthorizationCheckpointsFromSlot(_ items: [StrictAuthorizationSlot]) -> [AuthorizationCheckpoint] {
        var out: [AuthorizationCheckpoint] = []
        for item in items {
            let derived = newAuthorizationCheckpoint(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectAuthorizationCheckpoint(_ item: AuthorizationCheckpoint) -> String {
        return classifyAuthorizationRollup(item.adjustedLoad())
    }
}
