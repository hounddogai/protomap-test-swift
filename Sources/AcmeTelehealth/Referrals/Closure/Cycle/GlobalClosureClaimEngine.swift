import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the global closure claim calculation.
    protocol GlobalClosureClaimAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalClosureClaim, value: Double) -> Double
    }

    final class FlaggedGlobalClosureClaimAdjuster: GlobalClosureClaimAdjuster {
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

        func adjust(_ item: GlobalClosureClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WardGlobalClosureClaimAdjuster: GlobalClosureClaimAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: GlobalClosureClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentGlobalClosureClaimAdjuster: GlobalClosureClaimAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalClosureClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingGlobalClosureClaimAdjuster: GlobalClosureClaimAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalClosureClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the global closure claim steps in order and keeps a trace of each.
    final class GlobalClosureClaimEngine {
        var steps: [any GlobalClosureClaimAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalClosureClaimAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalClosureClaim) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalClosureClaimAdjuster = steps[index]
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

        func evaluateAll(_ items: [GlobalClosureClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalClosureClaimEngine(_ flags: Kit.Flags.Registry) -> GlobalClosureClaimEngine {
        return GlobalClosureClaimEngine(
            steps: [
                FlaggedGlobalClosureClaimAdjuster(flags: flags, flag: "global-closure-claim-pending", percent: 1.3),
                WardGlobalClosureClaimAdjuster(factors: ["south": 0.79]),
                PercentGlobalClosureClaimAdjuster(percent: -20.5),
                RoundingGlobalClosureClaimAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 73474.7
        )
    }
}
