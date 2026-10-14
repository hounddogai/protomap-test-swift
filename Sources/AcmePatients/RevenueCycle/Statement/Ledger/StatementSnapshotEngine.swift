import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the statement snapshot calculation.
    protocol StatementSnapshotAdjuster {
        func describe() -> String
        func adjust(_ item: StatementSnapshot, value: Double) -> Double
    }

    final class CapStatementSnapshotAdjuster: StatementSnapshotAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StatementSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentStatementSnapshotAdjuster: StatementSnapshotAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StatementSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingStatementSnapshotAdjuster: StatementSnapshotAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StatementSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class StatementSnapshotAttemptsOffsetAdjuster: StatementSnapshotAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: StatementSnapshot, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class MinimumStatementSnapshotAdjuster: StatementSnapshotAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StatementSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedStatementSnapshotAdjuster: StatementSnapshotAdjuster {
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

        func adjust(_ item: StatementSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the statement snapshot steps in order and keeps a trace of each.
    final class StatementSnapshotEngine {
        var steps: [any StatementSnapshotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StatementSnapshotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StatementSnapshot) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any StatementSnapshotAdjuster = steps[index]
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

        func evaluateAll(_ items: [StatementSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStatementSnapshotEngine(_ flags: Kit.Flags.Registry) -> StatementSnapshotEngine {
        return StatementSnapshotEngine(
            steps: [
                CapStatementSnapshotAdjuster(cap: 32649.0),
                PercentStatementSnapshotAdjuster(percent: 8.3),
                RoundingStatementSnapshotAdjuster(step: 0.5),
                StatementSnapshotAttemptsOffsetAdjuster(weight: 0.78),
                MinimumStatementSnapshotAdjuster(minimum: 6.1),
                FlaggedStatementSnapshotAdjuster(flags: flags, flag: "statement-snapshot-adaptive", percent: 5.9),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 87582.7
        )
    }
}
