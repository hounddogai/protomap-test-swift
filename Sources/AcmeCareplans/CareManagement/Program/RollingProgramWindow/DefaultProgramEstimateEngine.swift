import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the default program estimate calculation.
    protocol DefaultProgramEstimateFactor {
        func describe() -> String
        func adjust(_ item: DefaultProgramEstimate, value: Double) -> Double
    }

    final class SegmentDefaultProgramEstimateAdjuster: DefaultProgramEstimateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: DefaultProgramEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedDefaultProgramEstimateAdjuster: DefaultProgramEstimateFactor {
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

        func adjust(_ item: DefaultProgramEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDefaultProgramEstimateAdjuster: DefaultProgramEstimateFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultProgramEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingDefaultProgramEstimateAdjuster: DefaultProgramEstimateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultProgramEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumDefaultProgramEstimateAdjuster: DefaultProgramEstimateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultProgramEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class DefaultProgramEstimateQuantityOffsetAdjuster: DefaultProgramEstimateFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: DefaultProgramEstimate, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    /// Runs the default program estimate steps in order and keeps a trace of each.
    final class DefaultProgramEstimateEngine {
        var steps: [any DefaultProgramEstimateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultProgramEstimateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultProgramEstimate) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultProgramEstimateFactor = steps[index]
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

        func evaluateAll(_ items: [DefaultProgramEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultProgramEstimateEngine(_ flags: Kit.Flags.Registry) -> DefaultProgramEstimateEngine {
        return DefaultProgramEstimateEngine(
            steps: [
                SegmentDefaultProgramEstimateAdjuster(factors: ["south": 0.94]),
                FlaggedDefaultProgramEstimateAdjuster(
                    flags: flags,
                    flag: "default-program-estimate-batched",
                    percent: -3.4
                ),
                TieredDefaultProgramEstimateAdjuster(bounds: [1715.0, 4303.0], rates: [1.1, 1.11]),
                RoundingDefaultProgramEstimateAdjuster(step: 0.05),
                MinimumDefaultProgramEstimateAdjuster(minimum: 11.5),
                DefaultProgramEstimateQuantityOffsetAdjuster(weight: 0.98),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 13561.6
        )
    }
}
