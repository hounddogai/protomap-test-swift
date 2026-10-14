import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStudyMappingsForAdjustment(_ items: [StudyMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveReadAdjustmentsFromMapping(_ items: [StudyMapping]) -> [ReadAdjustment] {
        var out: [ReadAdjustment] = []
        for item in items {
            let derived = newReadAdjustment(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreReadAdjustment(_ item: ReadAdjustment) -> String {
        return normalizeLenientStudyMetricCode(item.code)
    }
}
