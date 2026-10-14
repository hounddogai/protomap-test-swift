import AcmePlatform
import Foundation

extension Consent {
    static func summarizeProxySchedulesForVariance(_ items: [ProxySchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveWitnessVariancesFromSchedule(_ items: [ProxySchedule]) -> [WitnessVariance] {
        var out: [WitnessVariance] = []
        for item in items {
            let derived = newWitnessVariance(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyWitnessVariance(_ item: WitnessVariance) -> String {
        return classifyProxySchedule(item.projectedExposure())
    }
}
