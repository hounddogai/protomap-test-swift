import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeLenientWorklistGroupsForRequest(_ items: [LenientWorklistGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveCareProtocolRequestsFromGroup(_ items: [LenientWorklistGroup]) -> [CareProtocolRequest] {
        var out: [CareProtocolRequest] = []
        for item in items {
            let derived = newCareProtocolRequest(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateCareProtocolRequest(_ item: CareProtocolRequest) -> String {
        return normalizeTieredWorklistEntryCode(item.code)
    }
}
