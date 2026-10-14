import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCensusTiersForAssignment(_ items: [CensusTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveTransferAssignmentsFromTier(_ items: [CensusTier]) -> [TransferAssignment] {
        var out: [TransferAssignment] = []
        for item in items {
            let derived = newTransferAssignment(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchTransferAssignment(_ item: TransferAssignment) -> Double {
        return scheduledCensusAgreementWeight(9, active: true)
    }
}
