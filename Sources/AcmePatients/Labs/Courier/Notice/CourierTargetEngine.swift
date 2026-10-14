import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier target calculation.
    protocol CourierTargetStep {
        func describe() -> String
        func adjust(_ item: CourierTarget, value: Double) -> Double
    }

    final class RoundingCourierTargetAdjuster: CourierTargetStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CourierTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredCourierTargetAdjuster: CourierTargetStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CourierTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapCourierTargetAdjuster: CourierTargetStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CourierTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class WardCourierTargetAdjuster: CourierTargetStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: CourierTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedCourierTargetAdjuster: CourierTargetStep {
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

        func adjust(_ item: CourierTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCourierTargetAdjuster: CourierTargetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CourierTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the courier target steps in order and keeps a trace of each.
    final class CourierTargetEngine {
        var steps: [any CourierTargetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierTargetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CourierTarget) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CourierTargetStep = steps[index]
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

        func evaluateAll(_ items: [CourierTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCourierTargetEngine(_ flags: Kit.Flags.Registry) -> CourierTargetEngine {
        return CourierTargetEngine(
            steps: [
                RoundingCourierTargetAdjuster(step: 0.5),
                TieredCourierTargetAdjuster(bounds: [925.0, 4666.0, 5674.0], rates: [0.84, 0.9, 0.85]),
                CapCourierTargetAdjuster(cap: 5615.0),
                WardCourierTargetAdjuster(factors: ["central": 1.28, "west": 1.02]),
                FlaggedCourierTargetAdjuster(flags: flags, flag: "courier-target-capped", percent: 7.0),
                MinimumCourierTargetAdjuster(minimum: 38.5),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 97825.7
        )
    }
}
