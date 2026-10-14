import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeSeasonalCredentialTargetsForSummary(_ items: [SeasonalCredentialTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveManualFloatPoolSummariesFromTarget(_ items: [SeasonalCredentialTarget]) -> [ManualFloatPoolSummary] {
        var out: [ManualFloatPoolSummary] = []
        for item in items {
            let derived = newManualFloatPoolSummary(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeManualFloatPoolSummary(_ item: ManualFloatPoolSummary) -> String {
        return classifyCredentialForecast(item.netTotal())
    }
}
