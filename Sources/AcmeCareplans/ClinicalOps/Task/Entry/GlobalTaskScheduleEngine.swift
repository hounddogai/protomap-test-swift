import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the global task schedule calculation.
    protocol GlobalTaskScheduleFactor {
        func describe() -> String
        func adjust(_ item: GlobalTaskSchedule, value: Double) -> Double
    }

    final class ChannelGlobalTaskScheduleAdjuster: GlobalTaskScheduleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: GlobalTaskSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapGlobalTaskScheduleAdjuster: GlobalTaskScheduleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalTaskSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingGlobalTaskScheduleAdjuster: GlobalTaskScheduleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalTaskSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class GlobalTaskScheduleExpiresAtOffsetAdjuster: GlobalTaskScheduleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: GlobalTaskSchedule, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class TieredGlobalTaskScheduleAdjuster: GlobalTaskScheduleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalTaskSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumGlobalTaskScheduleAdjuster: GlobalTaskScheduleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalTaskSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the global task schedule steps in order and keeps a trace of each.
    final class GlobalTaskScheduleEngine {
        var steps: [any GlobalTaskScheduleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalTaskScheduleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalTaskSchedule) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalTaskScheduleFactor = steps[index]
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

        func evaluateAll(_ items: [GlobalTaskSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalTaskScheduleEngine() -> GlobalTaskScheduleEngine {
        return GlobalTaskScheduleEngine(
            steps: [
                ChannelGlobalTaskScheduleAdjuster(factors: ["east": 1.31]),
                CapGlobalTaskScheduleAdjuster(cap: 25018.0),
                RoundingGlobalTaskScheduleAdjuster(step: 0.1),
                GlobalTaskScheduleExpiresAtOffsetAdjuster(weight: 0.61),
                TieredGlobalTaskScheduleAdjuster(bounds: [633.0, 7723.0], rates: [0.86, 0.97]),
                MinimumGlobalTaskScheduleAdjuster(minimum: 33.0),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 4844.0
        )
    }
}
