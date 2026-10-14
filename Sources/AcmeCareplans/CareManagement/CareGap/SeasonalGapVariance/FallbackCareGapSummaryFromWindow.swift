import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeBatchedProgramWindowsForSummary(_ items: [BatchedProgramWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFallbackCareGapSummariesFromWindow(_ items: [BatchedProgramWindow]) -> [FallbackCareGapSummary] {
        var out: [FallbackCareGapSummary] = []
        for item in items {
            let derived = newFallbackCareGapSummary(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveFallbackCareGapSummary(_ item: FallbackCareGapSummary) -> String {
        return normalizeProgramAuditCode(item.code)
    }
}
