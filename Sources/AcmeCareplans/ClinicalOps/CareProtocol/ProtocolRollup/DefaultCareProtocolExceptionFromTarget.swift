import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizePendingHandoffTargetsForException(_ items: [PendingHandoffTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveDefaultCareProtocolExceptionsFromTarget(_ items: [PendingHandoffTarget]) -> [DefaultCareProtocolException] {
        var out: [DefaultCareProtocolException] = []
        for item in items {
            let derived = newDefaultCareProtocolException(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyDefaultCareProtocolException(_ item: DefaultCareProtocolException) -> String {
        return normalizeManualHandoffScheduleCode(item.code)
    }
}
