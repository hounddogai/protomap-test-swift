import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeReadManifestsForMapping(_ items: [ReadManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveCareProtocolMappingsFromManifest(_ items: [ReadManifest]) -> [CareProtocolMapping] {
        var out: [CareProtocolMapping] = []
        for item in items {
            let derived = newCareProtocolMapping(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileCareProtocolMapping(_ item: CareProtocolMapping) -> String {
        return readAllocationBucket(item.measuredValue())
    }
}
