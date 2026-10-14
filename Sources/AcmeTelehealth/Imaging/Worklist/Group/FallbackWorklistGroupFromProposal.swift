import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeLenientReadProposalsForGroup(_ items: [LenientReadProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveFallbackWorklistGroupsFromProposal(_ items: [LenientReadProposal]) -> [FallbackWorklistGroup] {
        var out: [FallbackWorklistGroup] = []
        for item in items {
            let derived = newFallbackWorklistGroup(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeFallbackWorklistGroup(_ item: FallbackWorklistGroup) -> String {
        return normalizePendingReadReservationCode(item.code)
    }
}
