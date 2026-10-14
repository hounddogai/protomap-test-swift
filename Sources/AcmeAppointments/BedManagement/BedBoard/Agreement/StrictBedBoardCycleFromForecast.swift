import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeLegacyIsolationForecastsForCycle(_ items: [LegacyIsolationForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveStrictBedBoardCyclesFromForecast(_ items: [LegacyIsolationForecast]) -> [StrictBedBoardCycle] {
        var out: [StrictBedBoardCycle] = []
        for item in items {
            let derived = newStrictBedBoardCycle(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func planStrictBedBoardCycle(_ item: StrictBedBoardCycle) -> String {
        return normalizeIsolationAgreementCode(item.code)
    }
}
