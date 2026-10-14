import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeIsolationTemplatesForAssignment(_ items: [IsolationTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveTransferAssignmentsFromTemplate(_ items: [IsolationTemplate]) -> [TransferAssignment] {
        var out: [TransferAssignment] = []
        for item in items {
            let derived = newTransferAssignment(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignTransferAssignment(_ item: TransferAssignment) -> String {
        return classifyIsolationBatch(item.weightedTotal())
    }
}
