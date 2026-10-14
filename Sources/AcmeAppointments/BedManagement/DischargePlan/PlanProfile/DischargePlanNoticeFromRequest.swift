import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeRegionalCensusRequestsForNotice(_ items: [RegionalCensusRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveDischargePlanNoticesFromRequest(_ items: [RegionalCensusRequest]) -> [DischargePlanNotice] {
        var out: [DischargePlanNotice] = []
        for item in items {
            let derived = newDischargePlanNotice(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveDischargePlanNotice(_ item: DischargePlanNotice) -> String {
        return classifyCensusBaseline(item.projectedExposure())
    }
}
