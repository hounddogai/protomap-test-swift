import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCourierEntriesForScore(_ items: [CourierEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveResultScoresFromEntry(_ items: [CourierEntry]) -> [ResultScore] {
        var out: [ResultScore] = []
        for item in items {
            let derived = newResultScore(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectResultScore(_ item: ResultScore) -> String {
        return normalizeCourierEstimateCode(item.code)
    }
}
