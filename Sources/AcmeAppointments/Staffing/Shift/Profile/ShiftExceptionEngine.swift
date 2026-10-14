import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the shift exception calculation.
    protocol ShiftExceptionFactor {
        func describe() -> String
        func adjust(_ item: ShiftException, value: Double) -> Double
    }

    final class PercentShiftExceptionAdjuster: ShiftExceptionFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ShiftException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumShiftExceptionAdjuster: ShiftExceptionFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ShiftException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredShiftExceptionAdjuster: ShiftExceptionFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ShiftException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedShiftExceptionAdjuster: ShiftExceptionFactor {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: ShiftException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingShiftExceptionAdjuster: ShiftExceptionFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ShiftException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the shift exception steps in order and keeps a trace of each.
    final class ShiftExceptionEngine {
        var steps: [any ShiftExceptionFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ShiftExceptionFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ShiftException) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ShiftExceptionFactor = steps[index]
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

        func evaluateAll(_ items: [ShiftException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultShiftExceptionEngine(_ flags: Kit.Flags.Registry) -> ShiftExceptionEngine {
        return ShiftExceptionEngine(
            steps: [
                PercentShiftExceptionAdjuster(percent: 17.0),
                MinimumShiftExceptionAdjuster(minimum: 37.4),
                TieredShiftExceptionAdjuster(bounds: [633.0, 5497.0, 6380.0, 6607.0], rates: [0.94, 0.86, 1.14, 0.81]),
                FlaggedShiftExceptionAdjuster(flags: flags, flag: "shift-exception-lenient", percent: -9.4),
                RoundingShiftExceptionAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 8430.1
        )
    }
}
