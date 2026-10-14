import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the lenient risk score preference calculation.
    protocol LenientRiskScorePreferenceAdjuster {
        func describe() -> String
        func adjust(_ item: LenientRiskScorePreference, value: Double) -> Double
    }

    final class PercentLenientRiskScorePreferenceAdjuster: LenientRiskScorePreferenceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientRiskScorePreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedLenientRiskScorePreferenceAdjuster: LenientRiskScorePreferenceAdjuster {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: LenientRiskScorePreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LenientRiskScorePreferenceGraceDaysOffsetAdjuster: LenientRiskScorePreferenceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: LenientRiskScorePreference, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class TieredLenientRiskScorePreferenceAdjuster: LenientRiskScorePreferenceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientRiskScorePreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleLenientRiskScorePreferenceAdjuster: LenientRiskScorePreferenceAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LenientRiskScorePreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the lenient risk score preference steps in order and keeps a trace of each.
    final class LenientRiskScorePreferenceEngine {
        var steps: [any LenientRiskScorePreferenceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientRiskScorePreferenceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientRiskScorePreference) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [LenientRiskScorePreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientRiskScorePreferenceEngine(_ flags: Kit.Flags.Registry) -> LenientRiskScorePreferenceEngine {
        return LenientRiskScorePreferenceEngine(
            steps: [
                PercentLenientRiskScorePreferenceAdjuster(percent: -15.9),
                FlaggedLenientRiskScorePreferenceAdjuster(
                    flags: flags,
                    flag: "lenient-risk-score-preference-seasonal",
                    percent: 2.2
                ),
                LenientRiskScorePreferenceGraceDaysOffsetAdjuster(weight: 1.11),
                TieredLenientRiskScorePreferenceAdjuster(
                    bounds: [208.0, 6354.0, 9651.0, 9823.0],
                    rates: [1.01, 0.9, 0.85, 1.17]
                ),
                TitleLenientRiskScorePreferenceAdjuster(factors: ["online": 0.72]),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 12577.5
        )
    }
}
