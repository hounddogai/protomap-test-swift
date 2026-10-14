import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier exception calculation.
    protocol CourierExceptionFactor {
        func describe() -> String
        func adjust(_ item: CourierException, value: Double) -> Double
    }

    final class TitleCourierExceptionAdjuster: CourierExceptionFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: CourierException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredCourierExceptionAdjuster: CourierExceptionFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CourierException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingCourierExceptionAdjuster: CourierExceptionFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CourierException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumCourierExceptionAdjuster: CourierExceptionFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CourierException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CourierExceptionCreatedAtOffsetAdjuster: CourierExceptionFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: CourierException, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class FlaggedCourierExceptionAdjuster: CourierExceptionFactor {
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

        func adjust(_ item: CourierException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the courier exception steps in order and keeps a trace of each.
    final class CourierExceptionEngine {
        var steps: [any CourierExceptionFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierExceptionFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CourierException) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CourierExceptionFactor = steps[index]
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

        func evaluateAll(_ items: [CourierException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCourierExceptionEngine(_ flags: Kit.Flags.Registry) -> CourierExceptionEngine {
        return CourierExceptionEngine(
            steps: [
                TitleCourierExceptionAdjuster(factors: ["central": 0.95, "retail": 0.95]),
                TieredCourierExceptionAdjuster(bounds: [8741.0, 9178.0], rates: [1.11, 0.84]),
                RoundingCourierExceptionAdjuster(step: 1.0),
                MinimumCourierExceptionAdjuster(minimum: 47.7),
                CourierExceptionCreatedAtOffsetAdjuster(weight: 0.85),
                FlaggedCourierExceptionAdjuster(flags: flags, flag: "courier-exception-legacy", percent: -1.1),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 81655.6
        )
    }
}
