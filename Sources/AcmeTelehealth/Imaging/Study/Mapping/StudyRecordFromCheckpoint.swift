import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeCareProtocolCheckpointsForRecord(_ items: [CareProtocolCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveStudyRecordsFromCheckpoint(_ items: [CareProtocolCheckpoint]) -> [StudyRecord] {
        var out: [StudyRecord] = []
        for item in items {
            let derived = newStudyRecord(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeStudyRecord(_ item: StudyRecord) -> String {
        return classifyCareProtocolGroup(item.netLoad())
    }
}
