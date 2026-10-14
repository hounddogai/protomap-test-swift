import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeTieredStudySummariesForBaseline(_ items: [TieredStudySummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveModalityBaselinesFromSummary(_ items: [TieredStudySummary]) -> [ModalityBaseline] {
        var out: [ModalityBaseline] = []
        for item in items {
            let derived = newModalityBaseline(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankModalityBaseline(_ item: ModalityBaseline) -> String {
        return globalStudyCheckpointBucket(item.projectedValue())
    }
}
