import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStrictWorklistClaimsForMapping(_ items: [StrictWorklistClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveLenientReadMappingsFromClaim(_ items: [StrictWorklistClaim]) -> [LenientReadMapping] {
        var out: [LenientReadMapping] = []
        for item in items {
            let derived = newLenientReadMapping(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyLenientReadMapping(_ item: LenientReadMapping) -> String {
        return classifyManualWorklistDigest(item.effectiveTotal())
    }
}
