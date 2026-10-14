import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the strict formulary policy calculation.
    protocol StrictFormularyPolicyAdjuster {
        func describe() -> String
        func adjust(_ item: StrictFormularyPolicy, value: Double) -> Double
    }

    final class FlaggedStrictFormularyPolicyAdjuster: StrictFormularyPolicyAdjuster {
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

        func adjust(_ item: StrictFormularyPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingStrictFormularyPolicyAdjuster: StrictFormularyPolicyAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictFormularyPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumStrictFormularyPolicyAdjuster: StrictFormularyPolicyAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictFormularyPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapStrictFormularyPolicyAdjuster: StrictFormularyPolicyAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictFormularyPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the strict formulary policy steps in order and keeps a trace of each.
    final class StrictFormularyPolicyEngine {
        var steps: [any StrictFormularyPolicyAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictFormularyPolicyAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StrictFormularyPolicy) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictFormularyPolicyAdjuster = steps[index]
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

        func evaluateAll(_ items: [StrictFormularyPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStrictFormularyPolicyEngine(_ flags: Kit.Flags.Registry) -> StrictFormularyPolicyEngine {
        return StrictFormularyPolicyEngine(
            steps: [
                FlaggedStrictFormularyPolicyAdjuster(
                    flags: flags,
                    flag: "strict-formulary-policy-manual",
                    percent: -1.9
                ),
                RoundingStrictFormularyPolicyAdjuster(step: 0.05),
                MinimumStrictFormularyPolicyAdjuster(minimum: 45.4),
                CapStrictFormularyPolicyAdjuster(cap: 21525.0),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 15166.6
        )
    }
}
