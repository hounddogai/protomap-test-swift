import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertGroupsForBaseline(_ items: [AlertGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCareProtocolBaselinesFromGroup(_ items: [AlertGroup]) -> [CareProtocolBaseline] {
        var out: [CareProtocolBaseline] = []
        for item in items {
            let derived = newCareProtocolBaseline(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateCareProtocolBaseline(_ item: CareProtocolBaseline) -> String {
        return alertGroupBucket(item.projectedExposure())
    }
}
