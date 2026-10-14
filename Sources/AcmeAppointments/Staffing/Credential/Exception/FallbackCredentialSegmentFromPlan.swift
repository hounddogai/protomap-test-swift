import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeOvertimePlansForSegment(_ items: [OvertimePlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveFallbackCredentialSegmentsFromPlan(_ items: [OvertimePlan]) -> [FallbackCredentialSegment] {
        var out: [FallbackCredentialSegment] = []
        for item in items {
            let derived = newFallbackCredentialSegment(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveFallbackCredentialSegment(_ item: FallbackCredentialSegment) -> String {
        return classifyOvertimeScore(item.effectiveTotal())
    }
}
