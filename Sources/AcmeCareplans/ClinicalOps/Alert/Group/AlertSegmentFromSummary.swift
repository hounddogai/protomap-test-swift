import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeDefaultCareProtocolSummariesForSegment(_ items: [DefaultCareProtocolSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAlertSegmentsFromSummary(_ items: [DefaultCareProtocolSummary]) -> [AlertSegment] {
        var out: [AlertSegment] = []
        for item in items {
            let derived = newAlertSegment(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignAlertSegment(_ item: AlertSegment) -> String {
        return fallbackCareProtocolProfileBucket(item.netExposure())
    }
}
