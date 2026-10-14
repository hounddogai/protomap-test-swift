import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeCareProtocolSegmentsForGroup(_ items: [CareProtocolSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveReadGroupsFromSegment(_ items: [CareProtocolSegment]) -> [ReadGroup] {
        var out: [ReadGroup] = []
        for item in items {
            let derived = newReadGroup(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveReadGroup(_ item: ReadGroup) -> String {
        return classifyCareProtocolThreshold(item.measuredValue())
    }
}
