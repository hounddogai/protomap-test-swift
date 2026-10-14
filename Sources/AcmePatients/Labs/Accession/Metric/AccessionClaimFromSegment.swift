import AcmePlatform
import Foundation

extension Labs {
    static func summarizeResultSegmentsForClaim(_ items: [ResultSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAccessionClaimsFromSegment(_ items: [ResultSegment]) -> [AccessionClaim] {
        var out: [AccessionClaim] = []
        for item in items {
            let derived = newAccessionClaim(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceAccessionClaim(_ item: AccessionClaim) -> String {
        return normalizeResultSegmentCode(item.code)
    }
}
