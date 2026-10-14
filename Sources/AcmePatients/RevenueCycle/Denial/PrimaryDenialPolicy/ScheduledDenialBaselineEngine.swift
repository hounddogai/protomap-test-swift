import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the scheduled denial baseline calculation.
    protocol ScheduledDenialBaselineAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledDenialBaseline, value: Double) -> Double
    }

    final class RoundingScheduledDenialBaselineAdjuster: ScheduledDenialBaselineAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledDenialBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentScheduledDenialBaselineAdjuster: ScheduledDenialBaselineAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledDenialBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapScheduledDenialBaselineAdjuster: ScheduledDenialBaselineAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledDenialBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ScheduledDenialBaselineRefillsOffsetAdjuster: ScheduledDenialBaselineAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: ScheduledDenialBaseline, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class MinimumScheduledDenialBaselineAdjuster: ScheduledDenialBaselineAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledDenialBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredScheduledDenialBaselineAdjuster: ScheduledDenialBaselineAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledDenialBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the scheduled denial baseline steps in order and keeps a trace of each.
    final class ScheduledDenialBaselineEngine {
        var steps: [any ScheduledDenialBaselineAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledDenialBaselineAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ScheduledDenialBaseline) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledDenialBaselineAdjuster = steps[index]
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

        func evaluateAll(_ items: [ScheduledDenialBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultScheduledDenialBaselineEngine() -> ScheduledDenialBaselineEngine {
        return ScheduledDenialBaselineEngine(
            steps: [
                RoundingScheduledDenialBaselineAdjuster(step: 0.25),
                PercentScheduledDenialBaselineAdjuster(percent: -13.4),
                CapScheduledDenialBaselineAdjuster(cap: 18161.0),
                ScheduledDenialBaselineRefillsOffsetAdjuster(weight: 0.81),
                MinimumScheduledDenialBaselineAdjuster(minimum: 30.2),
                TieredScheduledDenialBaselineAdjuster(bounds: [2480.0, 3474.0, 4440.0], rates: [1.01, 0.93, 1.07]),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 51325.7
        )
    }
}
