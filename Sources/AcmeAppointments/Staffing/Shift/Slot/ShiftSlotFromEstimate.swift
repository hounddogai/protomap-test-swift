import AcmePlatform
import Foundation

extension Staffing {
    static func summarizePrimaryCredentialEstimatesForSlot(_ items: [PrimaryCredentialEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveShiftSlotsFromEstimate(_ items: [PrimaryCredentialEstimate]) -> [ShiftSlot] {
        var out: [ShiftSlot] = []
        for item in items {
            let derived = newShiftSlot(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeShiftSlot(_ item: ShiftSlot) -> String {
        return normalizeBatchedCredentialScheduleCode(item.code)
    }
}
