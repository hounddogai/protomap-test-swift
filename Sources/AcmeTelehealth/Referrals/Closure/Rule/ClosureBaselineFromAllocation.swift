import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeRollingReferralAllocationsForBaseline(_ items: [RollingReferralAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveClosureBaselinesFromAllocation(_ items: [RollingReferralAllocation]) -> [ClosureBaseline] {
        var out: [ClosureBaseline] = []
        for item in items {
            let derived = newClosureBaseline(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func planClosureBaseline(_ item: ClosureBaseline) -> String {
        return normalizeScheduledReferralMappingCode(item.code)
    }
}
