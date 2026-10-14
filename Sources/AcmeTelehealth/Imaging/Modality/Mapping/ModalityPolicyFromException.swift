import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStudyExceptionsForPolicy(_ items: [StudyException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveModalityPoliciesFromException(_ items: [StudyException]) -> [ModalityPolicy] {
        var out: [ModalityPolicy] = []
        for item in items {
            let derived = newModalityPolicy(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeModalityPolicy(_ item: ModalityPolicy) -> String {
        return studyMetricBucket(item.adjustedValue())
    }
}
