import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeWorklistSchedulesForScore(_ items: [WorklistSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveReadScoresFromSchedule(_ items: [WorklistSchedule]) -> [ReadScore] {
        var out: [ReadScore] = []
        for item in items {
            let derived = newReadScore(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchReadScore(_ item: ReadScore) -> String {
        return normalizeRollingWorklistScheduleCode(item.code)
    }
}
