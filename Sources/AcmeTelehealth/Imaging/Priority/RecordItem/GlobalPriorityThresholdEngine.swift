import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the global priority threshold calculation.
    protocol GlobalPriorityThresholdAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalPriorityThreshold, value: Double) -> Double
    }

    final class RoundingGlobalPriorityThresholdAdjuster: GlobalPriorityThresholdAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalPriorityThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentGlobalPriorityThresholdAdjuster: GlobalPriorityThresholdAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalPriorityThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumGlobalPriorityThresholdAdjuster: GlobalPriorityThresholdAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalPriorityThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameGlobalPriorityThresholdAdjuster: GlobalPriorityThresholdAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: GlobalPriorityThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapGlobalPriorityThresholdAdjuster: GlobalPriorityThresholdAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalPriorityThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the global priority threshold steps in order and keeps a trace of each.
    final class GlobalPriorityThresholdEngine {
        var steps: [any GlobalPriorityThresholdAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalPriorityThresholdAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalPriorityThreshold) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalPriorityThresholdAdjuster = steps[index]
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

        func evaluateAll(_ items: [GlobalPriorityThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalPriorityThresholdEngine() -> GlobalPriorityThresholdEngine {
        return GlobalPriorityThresholdEngine(
            steps: [
                RoundingGlobalPriorityThresholdAdjuster(step: 0.25),
                PercentGlobalPriorityThresholdAdjuster(percent: -24.9),
                MinimumGlobalPriorityThresholdAdjuster(minimum: 9.8),
                NameGlobalPriorityThresholdAdjuster(factors: ["north": 1.23]),
                CapGlobalPriorityThresholdAdjuster(cap: 25559.0),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 68810.4
        )
    }
}
