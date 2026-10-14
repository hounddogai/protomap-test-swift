import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeSeasonalOvertimeRecordsForManifest(_ items: [SeasonalOvertimeRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveStrictFloatPoolManifestsFromRecord(_ items: [SeasonalOvertimeRecord]) -> [StrictFloatPoolManifest] {
        var out: [StrictFloatPoolManifest] = []
        for item in items {
            let derived = newStrictFloatPoolManifest(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyStrictFloatPoolManifestExtra(_ item: StrictFloatPoolManifest) -> Double {
        return tieredOvertimeScoreWeight(7, active: true)
    }
}
