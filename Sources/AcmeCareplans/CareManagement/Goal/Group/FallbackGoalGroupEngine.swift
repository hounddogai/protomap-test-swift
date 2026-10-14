import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the fallback goal group calculation.
    protocol FallbackGoalGroupStep {
        func describe() -> String
        func adjust(_ item: FallbackGoalGroup, value: Double) -> Double
    }

    final class TieredFallbackGoalGroupAdjuster: FallbackGoalGroupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackGoalGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentFallbackGoalGroupAdjuster: FallbackGoalGroupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackGoalGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFallbackGoalGroupAdjuster: FallbackGoalGroupStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackGoalGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumFallbackGoalGroupAdjuster: FallbackGoalGroupStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackGoalGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the fallback goal group steps in order and keeps a trace of each.
    final class FallbackGoalGroupEngine {
        var steps: [any FallbackGoalGroupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackGoalGroupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackGoalGroup) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackGoalGroupStep = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [FallbackGoalGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackGoalGroupEngine() -> FallbackGoalGroupEngine {
        return FallbackGoalGroupEngine(
            steps: [
                TieredFallbackGoalGroupAdjuster(
                    bounds: [1063.0, 2568.0, 5214.0, 7764.0],
                    rates: [1.18, 1.01, 1.14, 1.04]
                ),
                PercentFallbackGoalGroupAdjuster(percent: -5.6),
                RoundingFallbackGoalGroupAdjuster(step: 0.25),
                MinimumFallbackGoalGroupAdjuster(minimum: 37.6),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 99913.0
        )
    }
}
