import AcmePlatform
import Foundation

extension Labs {
    /// One step of the reference range baseline calculation.
    protocol ReferenceRangeBaselineFactor {
        func describe() -> String
        func adjust(_ item: ReferenceRangeBaseline, value: Double) -> Double
    }

    final class FlaggedReferenceRangeBaselineAdjuster: ReferenceRangeBaselineFactor {
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

        func adjust(_ item: ReferenceRangeBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentReferenceRangeBaselineAdjuster: ReferenceRangeBaselineFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferenceRangeBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumReferenceRangeBaselineAdjuster: ReferenceRangeBaselineFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReferenceRangeBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CountryReferenceRangeBaselineAdjuster: ReferenceRangeBaselineFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: ReferenceRangeBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapReferenceRangeBaselineAdjuster: ReferenceRangeBaselineFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReferenceRangeBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingReferenceRangeBaselineAdjuster: ReferenceRangeBaselineFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferenceRangeBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the reference range baseline steps in order and keeps a trace of each.
    final class ReferenceRangeBaselineEngine {
        var steps: [any ReferenceRangeBaselineFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferenceRangeBaselineFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ReferenceRangeBaseline) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ReferenceRangeBaselineFactor = steps[index]
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

        func evaluateAll(_ items: [ReferenceRangeBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultReferenceRangeBaselineEngine(_ flags: Kit.Flags.Registry) -> ReferenceRangeBaselineEngine {
        return ReferenceRangeBaselineEngine(
            steps: [
                FlaggedReferenceRangeBaselineAdjuster(
                    flags: flags,
                    flag: "reference-range-baseline-primary",
                    percent: -2.7
                ),
                PercentReferenceRangeBaselineAdjuster(percent: 24.5),
                MinimumReferenceRangeBaselineAdjuster(minimum: 6.0),
                CountryReferenceRangeBaselineAdjuster(factors: ["east": 1.07, "central": 0.93]),
                CapReferenceRangeBaselineAdjuster(cap: 31388.0),
                RoundingReferenceRangeBaselineAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 36923.0
        )
    }
}
