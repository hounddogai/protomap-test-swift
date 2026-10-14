import AcmePlatform
import Foundation

extension Consent {
    /// One step of the global disclosure baseline calculation.
    protocol GlobalDisclosureBaselineModifier {
        func describe() -> String
        func adjust(_ item: GlobalDisclosureBaseline, value: Double) -> Double
    }

    final class FlaggedGlobalDisclosureBaselineAdjuster: GlobalDisclosureBaselineModifier {
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

        func adjust(_ item: GlobalDisclosureBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentGlobalDisclosureBaselineAdjuster: GlobalDisclosureBaselineModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalDisclosureBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumGlobalDisclosureBaselineAdjuster: GlobalDisclosureBaselineModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalDisclosureBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the global disclosure baseline steps in order and keeps a trace of each.
    final class GlobalDisclosureBaselineEngine {
        var steps: [any GlobalDisclosureBaselineModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalDisclosureBaselineModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GlobalDisclosureBaseline) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalDisclosureBaselineModifier = steps[index]
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

        func evaluateAll(_ items: [GlobalDisclosureBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGlobalDisclosureBaselineEngine(_ flags: Kit.Flags.Registry) -> GlobalDisclosureBaselineEngine {
        return GlobalDisclosureBaselineEngine(
            steps: [
                FlaggedGlobalDisclosureBaselineAdjuster(
                    flags: flags,
                    flag: "global-disclosure-baseline-legacy",
                    percent: 0.8
                ),
                PercentGlobalDisclosureBaselineAdjuster(percent: 20.5),
                MinimumGlobalDisclosureBaselineAdjuster(minimum: 48.2),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 39054.1
        )
    }
}
