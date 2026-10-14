import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeModalityRecordsForCheckpoint(_ items: [ModalityRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveStudyCheckpointsFromRecord(_ items: [ModalityRecord]) -> [StudyCheckpoint] {
        var out: [StudyCheckpoint] = []
        for item in items {
            let derived = newStudyCheckpoint(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateStudyCheckpoint(_ item: StudyCheckpoint) -> String {
        return classifyModalityRecord(item.adjustedTotal())
    }
}
