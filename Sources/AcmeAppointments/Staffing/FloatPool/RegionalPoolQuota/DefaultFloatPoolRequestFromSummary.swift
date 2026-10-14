import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeTieredShiftSummariesForRequest(_ items: [TieredShiftSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveDefaultFloatPoolRequestsFromSummary(_ items: [TieredShiftSummary]) -> [DefaultFloatPoolRequest] {
        var out: [DefaultFloatPoolRequest] = []
        for item in items {
            let derived = newDefaultFloatPoolRequest(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeDefaultFloatPoolRequest(_ item: DefaultFloatPoolRequest) -> String {
        return normalizeTieredShiftSummaryCode(item.code)
    }
}
