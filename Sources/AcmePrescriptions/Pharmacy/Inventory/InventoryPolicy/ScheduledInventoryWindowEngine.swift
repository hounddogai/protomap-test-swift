import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the scheduled inventory window calculation.
    protocol ScheduledInventoryWindowStep {
        func describe() -> String
        func adjust(_ item: ScheduledInventoryWindow, value: Double) -> Double
    }

    final class PercentScheduledInventoryWindowAdjuster: ScheduledInventoryWindowStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledInventoryWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumScheduledInventoryWindowAdjuster: ScheduledInventoryWindowStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledInventoryWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingScheduledInventoryWindowAdjuster: ScheduledInventoryWindowStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledInventoryWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapScheduledInventoryWindowAdjuster: ScheduledInventoryWindowStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledInventoryWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredScheduledInventoryWindowAdjuster: ScheduledInventoryWindowStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledInventoryWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the scheduled inventory window steps in order and keeps a trace of each.
    final class ScheduledInventoryWindowEngine {
        var steps: [any ScheduledInventoryWindowStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledInventoryWindowStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledInventoryWindow) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledInventoryWindowStep = steps[index]
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

        func evaluateAll(_ items: [ScheduledInventoryWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledInventoryWindowEngine() -> ScheduledInventoryWindowEngine {
        return ScheduledInventoryWindowEngine(
            steps: [
                PercentScheduledInventoryWindowAdjuster(percent: -23.9),
                MinimumScheduledInventoryWindowAdjuster(minimum: 49.0),
                RoundingScheduledInventoryWindowAdjuster(step: 0.5),
                CapScheduledInventoryWindowAdjuster(cap: 47764.0),
                TieredScheduledInventoryWindowAdjuster(bounds: [1924.0, 7366.0], rates: [1.19, 1.15]),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 2739.1
        )
    }
}
