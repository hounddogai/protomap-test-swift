import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCappedCredentialMilestonesForException(_ items: [CappedCredentialMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveLegacyShiftExceptionsFromMilestone(_ items: [CappedCredentialMilestone]) -> [LegacyShiftException] {
        var out: [LegacyShiftException] = []
        for item in items {
            let derived = newLegacyShiftException(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyLegacyShiftException(_ item: LegacyShiftException) -> Double {
        return regionalCredentialDraftWeight(8, active: true)
    }
}
