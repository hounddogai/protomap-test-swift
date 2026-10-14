import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the lenient goal variance calculation.
    protocol LenientGoalVarianceFactor {
        func describe() -> String
        func adjust(_ item: LenientGoalVariance, value: Double) -> Double
    }

    final class PercentLenientGoalVarianceAdjuster: LenientGoalVarianceFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientGoalVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelLenientGoalVarianceAdjuster: LenientGoalVarianceFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: LenientGoalVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredLenientGoalVarianceAdjuster: LenientGoalVarianceFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientGoalVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LenientGoalVarianceScoreOffsetAdjuster: LenientGoalVarianceFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: LenientGoalVariance, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    /// Runs the lenient goal variance steps in order and keeps a trace of each.
    final class LenientGoalVarianceEngine {
        var steps: [any LenientGoalVarianceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientGoalVarianceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientGoalVariance) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [LenientGoalVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientGoalVarianceEngine() -> LenientGoalVarianceEngine {
        return LenientGoalVarianceEngine(
            steps: [
                PercentLenientGoalVarianceAdjuster(percent: -8.9),
                ChannelLenientGoalVarianceAdjuster(factors: ["retail": 0.83, "west": 1.38]),
                TieredLenientGoalVarianceAdjuster(
                    bounds: [527.0, 2303.0, 6998.0, 8194.0],
                    rates: [1.15, 0.81, 1.13, 0.89]
                ),
                LenientGoalVarianceScoreOffsetAdjuster(weight: 0.33),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 9263.0
        )
    }
}
