import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the seasonal risk score variance calculation.
    protocol SeasonalRiskScoreVarianceAdjuster {
        func describe() -> String
        func adjust(_ item: SeasonalRiskScoreVariance, value: Double) -> Double
    }

    final class MinimumSeasonalRiskScoreVarianceAdjuster: SeasonalRiskScoreVarianceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalRiskScoreVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentSeasonalRiskScoreVarianceAdjuster: SeasonalRiskScoreVarianceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalRiskScoreVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingSeasonalRiskScoreVarianceAdjuster: SeasonalRiskScoreVarianceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalRiskScoreVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CountrySeasonalRiskScoreVarianceAdjuster: SeasonalRiskScoreVarianceAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: SeasonalRiskScoreVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class SeasonalRiskScoreVarianceScoreOffsetAdjuster: SeasonalRiskScoreVarianceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: SeasonalRiskScoreVariance, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class TieredSeasonalRiskScoreVarianceAdjuster: SeasonalRiskScoreVarianceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalRiskScoreVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the seasonal risk score variance steps in order and keeps a trace of each.
    final class SeasonalRiskScoreVarianceEngine {
        var steps: [any SeasonalRiskScoreVarianceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalRiskScoreVarianceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalRiskScoreVariance) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [SeasonalRiskScoreVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalRiskScoreVarianceEngine() -> SeasonalRiskScoreVarianceEngine {
        return SeasonalRiskScoreVarianceEngine(
            steps: [
                MinimumSeasonalRiskScoreVarianceAdjuster(minimum: 48.3),
                PercentSeasonalRiskScoreVarianceAdjuster(percent: 15.0),
                RoundingSeasonalRiskScoreVarianceAdjuster(step: 1.0),
                CountrySeasonalRiskScoreVarianceAdjuster(factors: ["south": 1.36, "online": 0.83, "west": 0.94]),
                SeasonalRiskScoreVarianceScoreOffsetAdjuster(weight: 0.83),
                TieredSeasonalRiskScoreVarianceAdjuster(bounds: [4529.0, 7125.0], rates: [0.89, 0.88]),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 82865.6
        )
    }
}
