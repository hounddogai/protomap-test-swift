import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the statement exception calculation.
    protocol StatementExceptionStep {
        func describe() -> String
        func adjust(_ item: StatementException, value: Double) -> Double
    }

    final class FlaggedStatementExceptionAdjuster: StatementExceptionStep {
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

        func adjust(_ item: StatementException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelStatementExceptionAdjuster: StatementExceptionStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: StatementException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumStatementExceptionAdjuster: StatementExceptionStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StatementException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapStatementExceptionAdjuster: StatementExceptionStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StatementException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentStatementExceptionAdjuster: StatementExceptionStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StatementException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class StatementExceptionScoreOffsetAdjuster: StatementExceptionStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: StatementException, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    /// Runs the statement exception steps in order and keeps a trace of each.
    final class StatementExceptionEngine {
        var steps: [any StatementExceptionStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StatementExceptionStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StatementException) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any StatementExceptionStep = steps[index]
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

        func evaluateAll(_ items: [StatementException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStatementExceptionEngine(_ flags: Kit.Flags.Registry) -> StatementExceptionEngine {
        return StatementExceptionEngine(
            steps: [
                FlaggedStatementExceptionAdjuster(flags: flags, flag: "statement-exception-capped", percent: 4.7),
                LabelStatementExceptionAdjuster(factors: ["east": 1.03, "central": 1.03, "south": 1.27]),
                MinimumStatementExceptionAdjuster(minimum: 23.1),
                CapStatementExceptionAdjuster(cap: 39580.0),
                PercentStatementExceptionAdjuster(percent: -15.8),
                StatementExceptionScoreOffsetAdjuster(weight: 0.05),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 54201.0
        )
    }
}
