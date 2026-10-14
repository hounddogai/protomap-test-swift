import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeLenientStudyMetricsForRecord(_ items: [LenientStudyMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveModalityRecordsFromMetric(_ items: [LenientStudyMetric]) -> [ModalityRecord] {
        var out: [ModalityRecord] = []
        for item in items {
            let derived = newModalityRecord(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyModalityRecordExtra(_ item: ModalityRecord) -> Double {
        return studyMappingWeight(7, active: true)
    }
}
