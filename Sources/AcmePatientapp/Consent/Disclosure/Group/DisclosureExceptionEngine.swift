import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure exception calculation.
    protocol DisclosureExceptionStep {
        func describe() -> String
        func adjust(_ item: DisclosureException, value: Double) -> Double
    }

    final class CapDisclosureExceptionAdjuster: DisclosureExceptionStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DisclosureException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumDisclosureExceptionAdjuster: DisclosureExceptionStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DisclosureException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredDisclosureExceptionAdjuster: DisclosureExceptionStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DisclosureException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class DisclosureExceptionBatchSizeOffsetAdjuster: DisclosureExceptionStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: DisclosureException, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class RoundingDisclosureExceptionAdjuster: DisclosureExceptionStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DisclosureException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedDisclosureExceptionAdjuster: DisclosureExceptionStep {
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

        func adjust(_ item: DisclosureException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the disclosure exception steps in order and keeps a trace of each.
    final class DisclosureExceptionEngine {
        var steps: [any DisclosureExceptionStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureExceptionStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DisclosureException) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DisclosureExceptionStep = steps[index]
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

        func evaluateAll(_ items: [DisclosureException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDisclosureExceptionEngine(_ flags: Kit.Flags.Registry) -> DisclosureExceptionEngine {
        return DisclosureExceptionEngine(
            steps: [
                CapDisclosureExceptionAdjuster(cap: 44387.0),
                MinimumDisclosureExceptionAdjuster(minimum: 12.4),
                TieredDisclosureExceptionAdjuster(bounds: [5276.0, 9425.0], rates: [0.9, 0.81]),
                DisclosureExceptionBatchSizeOffsetAdjuster(weight: 0.52),
                RoundingDisclosureExceptionAdjuster(step: 5.0),
                FlaggedDisclosureExceptionAdjuster(flags: flags, flag: "disclosure-exception-default", percent: -7.5),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 23040.8
        )
    }
}
