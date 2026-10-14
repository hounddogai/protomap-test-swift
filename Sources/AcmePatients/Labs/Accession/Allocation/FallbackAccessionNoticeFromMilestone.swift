import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAdaptiveCourierMilestonesForNotice(_ items: [AdaptiveCourierMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFallbackAccessionNoticesFromMilestone(_ items: [AdaptiveCourierMilestone]) -> [FallbackAccessionNotice] {
        var out: [FallbackAccessionNotice] = []
        for item in items {
            let derived = newFallbackAccessionNotice(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignFallbackAccessionNotice(_ item: FallbackAccessionNotice) -> String {
        return classifyFallbackCourierException(item.measuredValue())
    }
}
