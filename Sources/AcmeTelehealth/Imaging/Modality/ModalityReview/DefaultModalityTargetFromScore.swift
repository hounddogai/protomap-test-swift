import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeReadScoresForTarget(_ items: [ReadScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveDefaultModalityTargetsFromScore(_ items: [ReadScore]) -> [DefaultModalityTarget] {
        var out: [DefaultModalityTarget] = []
        for item in items {
            let derived = newDefaultModalityTarget(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignDefaultModalityTarget(_ item: DefaultModalityTarget) -> String {
        return readScoreBucket(item.adjustedLoad())
    }
}
