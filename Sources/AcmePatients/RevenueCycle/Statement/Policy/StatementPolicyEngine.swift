import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the statement policy calculation.
    protocol StatementPolicyStep {
        func describe() -> String
        func adjust(_ item: StatementPolicy, value: Double) -> Double
    }

    final class CountryStatementPolicyAdjuster: StatementPolicyStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: StatementPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumStatementPolicyAdjuster: StatementPolicyStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StatementPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedStatementPolicyAdjuster: StatementPolicyStep {
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

        func adjust(_ item: StatementPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingStatementPolicyAdjuster: StatementPolicyStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StatementPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapStatementPolicyAdjuster: StatementPolicyStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StatementPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentStatementPolicyAdjuster: StatementPolicyStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StatementPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the statement policy steps in order and keeps a trace of each.
    final class StatementPolicyEngine {
        var steps: [any StatementPolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StatementPolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StatementPolicy) -> Double {
            var current = item.projectedLoad()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [StatementPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStatementPolicyEngine(_ flags: Kit.Flags.Registry) -> StatementPolicyEngine {
        return StatementPolicyEngine(
            steps: [
                CountryStatementPolicyAdjuster(factors: ["east": 0.99]),
                MinimumStatementPolicyAdjuster(minimum: 49.5),
                FlaggedStatementPolicyAdjuster(flags: flags, flag: "statement-policy-rolling", percent: 5.8),
                RoundingStatementPolicyAdjuster(step: 5.0),
                CapStatementPolicyAdjuster(cap: 17930.0),
                PercentStatementPolicyAdjuster(percent: 15.8),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 55030.5
        )
    }
}
