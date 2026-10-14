import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeOvertimeRequestsForLedger(_ items: [OvertimeRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func derivePrimaryCredentialLedgersFromRequest(_ items: [OvertimeRequest]) -> [PrimaryCredentialLedger] {
        var out: [PrimaryCredentialLedger] = []
        for item in items {
            let derived = newPrimaryCredentialLedger(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimatePrimaryCredentialLedger(_ item: PrimaryCredentialLedger) -> String {
        return overtimeRequestBucket(item.effectiveLoad())
    }
}
