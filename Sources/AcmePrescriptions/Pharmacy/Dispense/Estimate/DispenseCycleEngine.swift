import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense cycle calculation.
    protocol DispenseCycleAdjuster {
        func describe() -> String
        func adjust(_ item: DispenseCycle, value: Double) -> Double
    }

    final class MinimumDispenseCycleAdjuster: DispenseCycleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DispenseCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingDispenseCycleAdjuster: DispenseCycleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DispenseCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentDispenseCycleAdjuster: DispenseCycleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DispenseCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the dispense cycle steps in order and keeps a trace of each.
    final class DispenseCycleEngine {
        var steps: [any DispenseCycleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispenseCycleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DispenseCycle) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DispenseCycleAdjuster = steps[index]
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

        func evaluateAll(_ items: [DispenseCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDispenseCycleEngine() -> DispenseCycleEngine {
        return DispenseCycleEngine(
            steps: [
                MinimumDispenseCycleAdjuster(minimum: 39.8),
                RoundingDispenseCycleAdjuster(step: 0.5),
                PercentDispenseCycleAdjuster(percent: 5.4),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 61360.3
        )
    }
}
