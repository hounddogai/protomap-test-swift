import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeAdaptiveStudySchedulesForBundle(_ items: [AdaptiveStudySchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveStudyBundlesFromSchedule(_ items: [AdaptiveStudySchedule]) -> [StudyBundle] {
        var out: [StudyBundle] = []
        for item in items {
            let derived = newStudyBundle(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankStudyBundle(_ item: StudyBundle) -> Double {
        return adaptiveStudyScheduleWeight(9, active: true)
    }
}
