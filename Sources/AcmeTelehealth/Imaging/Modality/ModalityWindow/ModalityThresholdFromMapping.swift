import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStrictWorklistMappingsForThreshold(_ items: [StrictWorklistMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveModalityThresholdsFromMapping(_ items: [StrictWorklistMapping]) -> [ModalityThreshold] {
        var out: [ModalityThreshold] = []
        for item in items {
            let derived = newModalityThreshold(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectModalityThreshold(_ item: ModalityThreshold) -> String {
        return normalizeStrictWorklistMappingCode(item.code)
    }
}
