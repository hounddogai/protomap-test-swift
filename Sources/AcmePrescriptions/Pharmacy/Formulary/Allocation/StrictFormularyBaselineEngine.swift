import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the strict formulary baseline calculation.
    protocol StrictFormularyBaselineAdjuster {
        func describe() -> String
        func adjust(_ item: StrictFormularyBaseline, value: Double) -> Double
    }

    final class MinimumStrictFormularyBaselineAdjuster: StrictFormularyBaselineAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictFormularyBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingStrictFormularyBaselineAdjuster: StrictFormularyBaselineAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictFormularyBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SegmentStrictFormularyBaselineAdjuster: StrictFormularyBaselineAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: StrictFormularyBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentStrictFormularyBaselineAdjuster: StrictFormularyBaselineAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictFormularyBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredStrictFormularyBaselineAdjuster: StrictFormularyBaselineAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictFormularyBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedStrictFormularyBaselineAdjuster: StrictFormularyBaselineAdjuster {
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

        func adjust(_ item: StrictFormularyBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict formulary baseline steps in order and keeps a trace of each.
    final class StrictFormularyBaselineEngine {
        var steps: [any StrictFormularyBaselineAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictFormularyBaselineAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictFormularyBaseline) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictFormularyBaselineAdjuster = steps[index]
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

        func evaluateAll(_ items: [StrictFormularyBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictFormularyBaselineEngine(_ flags: Kit.Flags.Registry) -> StrictFormularyBaselineEngine {
        return StrictFormularyBaselineEngine(
            steps: [
                MinimumStrictFormularyBaselineAdjuster(minimum: 4.1),
                RoundingStrictFormularyBaselineAdjuster(step: 0.1),
                SegmentStrictFormularyBaselineAdjuster(factors: ["online": 1.05, "west": 1.02]),
                PercentStrictFormularyBaselineAdjuster(percent: -3.3),
                TieredStrictFormularyBaselineAdjuster(bounds: [6900.0, 9239.0], rates: [0.83, 1.16]),
                FlaggedStrictFormularyBaselineAdjuster(
                    flags: flags,
                    flag: "strict-formulary-baseline-adaptive",
                    percent: 6.7
                ),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 25451.9
        )
    }
}
