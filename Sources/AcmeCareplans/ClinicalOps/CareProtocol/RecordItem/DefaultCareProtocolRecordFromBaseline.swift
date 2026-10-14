import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizePendingHandoffBaselinesForRecordRecordItem(_ items: [PendingHandoffBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveDefaultCareProtocolRecordsFromBaseline(_ items: [PendingHandoffBaseline]) -> [DefaultCareProtocolRecord] {
        var out: [DefaultCareProtocolRecord] = []
        for item in items {
            let derived = newDefaultCareProtocolRecord(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyDefaultCareProtocolRecord(_ item: DefaultCareProtocolRecord) -> String {
        return strictHandoffQuotaBucket(item.effectiveLoad())
    }
}
