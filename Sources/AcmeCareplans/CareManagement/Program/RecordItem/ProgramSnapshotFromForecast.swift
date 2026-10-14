import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeAdaptiveRiskScoreForecastsForSnapshot(_ items: [AdaptiveRiskScoreForecast]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveProgramSnapshotsFromForecast(_ items: [AdaptiveRiskScoreForecast]) -> [ProgramSnapshot] {
        var out: [ProgramSnapshot] = []
        for item in items {
            let derived = newProgramSnapshot(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleProgramSnapshot(_ item: ProgramSnapshot) -> String {
        return adaptiveRiskScoreMilestoneBucket(item.adjustedLoad())
    }
}
