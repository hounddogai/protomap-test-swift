import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePrimaryCareProtocolMappingsForEntry(_ items: [PrimaryCareProtocolMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveStrictModalityEntriesFromMapping(_ items: [PrimaryCareProtocolMapping]) -> [StrictModalityEntry] {
        var out: [StrictModalityEntry] = []
        for item in items {
            let derived = newStrictModalityEntry(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveStrictModalityEntry(_ item: StrictModalityEntry) -> Double {
        return globalCareProtocolBatchWeight(9, active: true)
    }
}
