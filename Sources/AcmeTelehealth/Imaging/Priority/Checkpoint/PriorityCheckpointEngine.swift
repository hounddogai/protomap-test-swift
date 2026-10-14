import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority checkpoint calculation.
    protocol PriorityCheckpointModifier {
        func describe() -> String
        func adjust(_ item: PriorityCheckpoint, value: Double) -> Double
    }

    final class TieredPriorityCheckpointAdjuster: PriorityCheckpointModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PriorityCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingPriorityCheckpointAdjuster: PriorityCheckpointModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PriorityCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class UnitPriorityCheckpointAdjuster: PriorityCheckpointModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: PriorityCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentPriorityCheckpointAdjuster: PriorityCheckpointModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PriorityCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPriorityCheckpointAdjuster: PriorityCheckpointModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PriorityCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the priority checkpoint steps in order and keeps a trace of each.
    final class PriorityCheckpointEngine {
        var steps: [any PriorityCheckpointModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PriorityCheckpointModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PriorityCheckpoint) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PriorityCheckpointModifier = steps[index]
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

        func evaluateAll(_ items: [PriorityCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPriorityCheckpointEngine() -> PriorityCheckpointEngine {
        return PriorityCheckpointEngine(
            steps: [
                TieredPriorityCheckpointAdjuster(bounds: [1120.0, 3843.0, 8009.0], rates: [0.83, 1.08, 1.14]),
                RoundingPriorityCheckpointAdjuster(step: 0.25),
                UnitPriorityCheckpointAdjuster(factors: ["west": 0.91, "east": 1.17]),
                PercentPriorityCheckpointAdjuster(percent: -3.7),
                MinimumPriorityCheckpointAdjuster(minimum: 30.6),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 14879.1
        )
    }
}
