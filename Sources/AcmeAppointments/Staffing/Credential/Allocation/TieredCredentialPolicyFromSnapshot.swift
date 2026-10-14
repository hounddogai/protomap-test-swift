import AcmePlatform
import Foundation

extension Staffing {
    static func summarizePendingOvertimeSnapshotsForPolicy(_ items: [PendingOvertimeSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveTieredCredentialPoliciesFromSnapshot(_ items: [PendingOvertimeSnapshot]) -> [TieredCredentialPolicy] {
        var out: [TieredCredentialPolicy] = []
        for item in items {
            let derived = newTieredCredentialPolicy(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func planTieredCredentialPolicy(_ item: TieredCredentialPolicy) -> String {
        return normalizeOvertimeAllocationCode(item.code)
    }
}
