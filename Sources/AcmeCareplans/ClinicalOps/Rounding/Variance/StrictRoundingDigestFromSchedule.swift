import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertSchedulesForDigest(_ items: [AlertSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveStrictRoundingDigestsFromSchedule(_ items: [AlertSchedule]) -> [StrictRoundingDigest] {
        var out: [StrictRoundingDigest] = []
        for item in items {
            let derived = newStrictRoundingDigest(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectStrictRoundingDigest(_ item: StrictRoundingDigest) -> String {
        return normalizeRegionalAlertSnapshotCode(item.code)
    }
}
