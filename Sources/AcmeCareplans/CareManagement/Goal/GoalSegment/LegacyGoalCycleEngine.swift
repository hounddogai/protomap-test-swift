import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the legacy goal cycle calculation.
    protocol LegacyGoalCycleFactor {
        func describe() -> String
        func adjust(_ item: LegacyGoalCycle, value: Double) -> Double
    }

    final class PercentLegacyGoalCycleAdjuster: LegacyGoalCycleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyGoalCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WardLegacyGoalCycleAdjuster: LegacyGoalCycleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: LegacyGoalCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredLegacyGoalCycleAdjuster: LegacyGoalCycleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyGoalCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapLegacyGoalCycleAdjuster: LegacyGoalCycleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyGoalCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumLegacyGoalCycleAdjuster: LegacyGoalCycleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyGoalCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the legacy goal cycle steps in order and keeps a trace of each.
    final class LegacyGoalCycleEngine {
        var steps: [any LegacyGoalCycleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyGoalCycleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyGoalCycle) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyGoalCycleFactor = steps[index]
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

        func evaluateAll(_ items: [LegacyGoalCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyGoalCycleEngine() -> LegacyGoalCycleEngine {
        return LegacyGoalCycleEngine(
            steps: [
                PercentLegacyGoalCycleAdjuster(percent: 10.9),
                WardLegacyGoalCycleAdjuster(factors: ["south": 0.73, "north": 1.02]),
                TieredLegacyGoalCycleAdjuster(bounds: [2578.0, 6238.0], rates: [1.08, 0.98]),
                CapLegacyGoalCycleAdjuster(cap: 11470.0),
                MinimumLegacyGoalCycleAdjuster(minimum: 26.4),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 86076.5
        )
    }
}
