import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the weighted interaction exception calculation.
    protocol WeightedInteractionExceptionAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedInteractionException, value: Double) -> Double
    }

    final class WeightedInteractionExceptionRateOffsetAdjuster: WeightedInteractionExceptionAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: WeightedInteractionException, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class MinimumWeightedInteractionExceptionAdjuster: WeightedInteractionExceptionAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedInteractionException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedWeightedInteractionExceptionAdjuster: WeightedInteractionExceptionAdjuster {
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

        func adjust(_ item: WeightedInteractionException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentWeightedInteractionExceptionAdjuster: WeightedInteractionExceptionAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedInteractionException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapWeightedInteractionExceptionAdjuster: WeightedInteractionExceptionAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedInteractionException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredWeightedInteractionExceptionAdjuster: WeightedInteractionExceptionAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedInteractionException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the weighted interaction exception steps in order and keeps a trace of each.
    final class WeightedInteractionExceptionEngine {
        var steps: [any WeightedInteractionExceptionAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedInteractionExceptionAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WeightedInteractionException) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedInteractionExceptionAdjuster = steps[index]
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

        func evaluateAll(_ items: [WeightedInteractionException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWeightedInteractionExceptionEngine(_ flags: Kit.Flags.Registry) -> WeightedInteractionExceptionEngine {
        return WeightedInteractionExceptionEngine(
            steps: [
                WeightedInteractionExceptionRateOffsetAdjuster(weight: 1.52),
                MinimumWeightedInteractionExceptionAdjuster(minimum: 43.5),
                FlaggedWeightedInteractionExceptionAdjuster(
                    flags: flags,
                    flag: "weighted-interaction-exception-capped",
                    percent: 2.6
                ),
                PercentWeightedInteractionExceptionAdjuster(percent: -19.3),
                CapWeightedInteractionExceptionAdjuster(cap: 8320.0),
                TieredWeightedInteractionExceptionAdjuster(bounds: [4394.0, 8551.0], rates: [1.08, 1.13]),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 67430.9
        )
    }
}
