import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the fallback statement assignment calculation.
    protocol FallbackStatementAssignmentFactor {
        func describe() -> String
        func adjust(_ item: FallbackStatementAssignment, value: Double) -> Double
    }

    final class RoundingFallbackStatementAssignmentAdjuster: FallbackStatementAssignmentFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackStatementAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleFallbackStatementAssignmentAdjuster: FallbackStatementAssignmentFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: FallbackStatementAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumFallbackStatementAssignmentAdjuster: FallbackStatementAssignmentFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackStatementAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedFallbackStatementAssignmentAdjuster: FallbackStatementAssignmentFactor {
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

        func adjust(_ item: FallbackStatementAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFallbackStatementAssignmentAdjuster: FallbackStatementAssignmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackStatementAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentFallbackStatementAssignmentAdjuster: FallbackStatementAssignmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackStatementAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback statement assignment steps in order and keeps a trace of each.
    final class FallbackStatementAssignmentEngine {
        var steps: [any FallbackStatementAssignmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackStatementAssignmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackStatementAssignment) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackStatementAssignmentFactor = steps[index]
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

        func evaluateAll(_ items: [FallbackStatementAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackStatementAssignmentEngine(_ flags: Kit.Flags.Registry) -> FallbackStatementAssignmentEngine {
        return FallbackStatementAssignmentEngine(
            steps: [
                RoundingFallbackStatementAssignmentAdjuster(step: 5.0),
                TitleFallbackStatementAssignmentAdjuster(factors: ["west": 1.19, "online": 1.01, "south": 1.12]),
                MinimumFallbackStatementAssignmentAdjuster(minimum: 26.7),
                FlaggedFallbackStatementAssignmentAdjuster(
                    flags: flags,
                    flag: "fallback-statement-assignment-global",
                    percent: 5.5
                ),
                CapFallbackStatementAssignmentAdjuster(cap: 14938.0),
                PercentFallbackStatementAssignmentAdjuster(percent: -2.2),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 3511.8
        )
    }
}
