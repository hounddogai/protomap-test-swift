import AcmePlatform
import Foundation

extension Consent {
    /// One step of the default disclosure summary calculation.
    protocol DefaultDisclosureSummaryModifier {
        func describe() -> String
        func adjust(_ item: DefaultDisclosureSummary, value: Double) -> Double
    }

    final class LocaleDefaultDisclosureSummaryAdjuster: DefaultDisclosureSummaryModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: DefaultDisclosureSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class DefaultDisclosureSummaryStartsAtOffsetAdjuster: DefaultDisclosureSummaryModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: DefaultDisclosureSummary, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class RoundingDefaultDisclosureSummaryAdjuster: DefaultDisclosureSummaryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultDisclosureSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapDefaultDisclosureSummaryAdjuster: DefaultDisclosureSummaryModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultDisclosureSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumDefaultDisclosureSummaryAdjuster: DefaultDisclosureSummaryModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultDisclosureSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedDefaultDisclosureSummaryAdjuster: DefaultDisclosureSummaryModifier {
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

        func adjust(_ item: DefaultDisclosureSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default disclosure summary steps in order and keeps a trace of each.
    final class DefaultDisclosureSummaryEngine {
        var steps: [any DefaultDisclosureSummaryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultDisclosureSummaryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultDisclosureSummary) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultDisclosureSummaryModifier = steps[index]
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

        func evaluateAll(_ items: [DefaultDisclosureSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultDisclosureSummaryEngine(_ flags: Kit.Flags.Registry) -> DefaultDisclosureSummaryEngine {
        return DefaultDisclosureSummaryEngine(
            steps: [
                LocaleDefaultDisclosureSummaryAdjuster(factors: ["retail": 1.12, "north": 1.06, "online": 1.37]),
                DefaultDisclosureSummaryStartsAtOffsetAdjuster(weight: 1.14),
                RoundingDefaultDisclosureSummaryAdjuster(step: 0.5),
                CapDefaultDisclosureSummaryAdjuster(cap: 9893.0),
                MinimumDefaultDisclosureSummaryAdjuster(minimum: 49.8),
                FlaggedDefaultDisclosureSummaryAdjuster(
                    flags: flags,
                    flag: "default-disclosure-summary-adaptive",
                    percent: -9.1
                ),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 79530.5
        )
    }
}
