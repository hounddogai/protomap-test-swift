import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeGlobalTransferAssignmentsForPlan(_ items: [GlobalTransferAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveTransferPlansFromAssignment(_ items: [GlobalTransferAssignment]) -> [TransferPlan] {
        var out: [TransferPlan] = []
        for item in items {
            let derived = newTransferPlan(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveTransferPlan(_ item: TransferPlan) -> String {
        return normalizeFallbackTransferRequestCode(item.code)
    }
}
