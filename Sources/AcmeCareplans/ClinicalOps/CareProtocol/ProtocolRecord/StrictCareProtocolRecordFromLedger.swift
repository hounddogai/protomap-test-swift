import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeLegacyHandoffLedgersForRecord(_ items: [LegacyHandoffLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveStrictCareProtocolRecordsFromLedger(_ items: [LegacyHandoffLedger]) -> [StrictCareProtocolRecord] {
        var out: [StrictCareProtocolRecord] = []
        for item in items {
            let derived = newStrictCareProtocolRecord(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyStrictCareProtocolRecord(_ item: StrictCareProtocolRecord) -> String {
        return classifyManualHandoffAssignment(item.projectedValue())
    }
}
