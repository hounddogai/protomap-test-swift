import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDefaultStatementMappingsForAdjustment(_ items: [DefaultStatementMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveTieredRemittanceAdjustmentsFromMapping(_ items: [DefaultStatementMapping]) -> [TieredRemittanceAdjustment] {
        var out: [TieredRemittanceAdjustment] = []
        for item in items {
            let derived = newTieredRemittanceAdjustment(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectTieredRemittanceAdjustment(_ item: TieredRemittanceAdjustment) -> String {
        return classifyStrictStatementForecast(item.projectedExposure())
    }
}
