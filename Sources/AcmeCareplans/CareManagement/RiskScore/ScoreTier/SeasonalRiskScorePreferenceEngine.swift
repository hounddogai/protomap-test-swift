import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the seasonal risk score preference calculation.
    protocol SeasonalRiskScorePreferenceFactor {
        func describe() -> String
        func adjust(_ item: SeasonalRiskScorePreference, value: Double) -> Double
    }

    final class TitleSeasonalRiskScorePreferenceAdjuster: SeasonalRiskScorePreferenceFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: SeasonalRiskScorePreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapSeasonalRiskScorePreferenceAdjuster: SeasonalRiskScorePreferenceFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalRiskScorePreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingSeasonalRiskScorePreferenceAdjuster: SeasonalRiskScorePreferenceFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalRiskScorePreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentSeasonalRiskScorePreferenceAdjuster: SeasonalRiskScorePreferenceFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalRiskScorePreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SeasonalRiskScorePreferenceScoreOffsetAdjuster: SeasonalRiskScorePreferenceFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: SeasonalRiskScorePreference, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    /// Runs the seasonal risk score preference steps in order and keeps a trace of each.
    final class SeasonalRiskScorePreferenceEngine {
        var steps: [any SeasonalRiskScorePreferenceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalRiskScorePreferenceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SeasonalRiskScorePreference) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [SeasonalRiskScorePreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSeasonalRiskScorePreferenceEngine() -> SeasonalRiskScorePreferenceEngine {
        return SeasonalRiskScorePreferenceEngine(
            steps: [
                TitleSeasonalRiskScorePreferenceAdjuster(factors: ["west": 1.12, "east": 0.93]),
                CapSeasonalRiskScorePreferenceAdjuster(cap: 2882.0),
                RoundingSeasonalRiskScorePreferenceAdjuster(step: 0.5),
                PercentSeasonalRiskScorePreferenceAdjuster(percent: -22.9),
                SeasonalRiskScorePreferenceScoreOffsetAdjuster(weight: 0.55),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 30322.2
        )
    }
}
