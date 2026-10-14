import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the default recall checkpoint calculation.
    protocol DefaultRecallCheckpointAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultRecallCheckpoint, value: Double) -> Double
    }

    final class MinimumDefaultRecallCheckpointAdjuster: DefaultRecallCheckpointAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultRecallCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameDefaultRecallCheckpointAdjuster: DefaultRecallCheckpointAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: DefaultRecallCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentDefaultRecallCheckpointAdjuster: DefaultRecallCheckpointAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultRecallCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDefaultRecallCheckpointAdjuster: DefaultRecallCheckpointAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultRecallCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class DefaultRecallCheckpointLimitOffsetAdjuster: DefaultRecallCheckpointAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: DefaultRecallCheckpoint, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    /// Runs the default recall checkpoint steps in order and keeps a trace of each.
    final class DefaultRecallCheckpointEngine {
        var steps: [any DefaultRecallCheckpointAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultRecallCheckpointAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultRecallCheckpoint) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultRecallCheckpointAdjuster = steps[index]
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

        func evaluateAll(_ items: [DefaultRecallCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultRecallCheckpointEngine() -> DefaultRecallCheckpointEngine {
        return DefaultRecallCheckpointEngine(
            steps: [
                MinimumDefaultRecallCheckpointAdjuster(minimum: 44.1),
                NameDefaultRecallCheckpointAdjuster(factors: ["east": 1.32, "south": 1.23, "north": 0.72]),
                PercentDefaultRecallCheckpointAdjuster(percent: 6.1),
                RoundingDefaultRecallCheckpointAdjuster(step: 0.05),
                DefaultRecallCheckpointLimitOffsetAdjuster(weight: 0.39),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 37064.9
        )
    }
}
