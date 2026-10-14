import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizePrimaryHandoffSlotsForSlot(_ items: [PrimaryHandoffSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveCareProtocolSlotsFromSlot(_ items: [PrimaryHandoffSlot]) -> [CareProtocolSlot] {
        var out: [CareProtocolSlot] = []
        for item in items {
            let derived = newCareProtocolSlot(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignCareProtocolSlot(_ item: CareProtocolSlot) -> String {
        return normalizeHandoffNoticeCode(item.code)
    }
}
