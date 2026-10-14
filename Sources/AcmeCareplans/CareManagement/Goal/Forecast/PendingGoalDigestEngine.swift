import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the pending goal digest calculation.
    protocol PendingGoalDigestAdjuster {
        func describe() -> String
        func adjust(_ item: PendingGoalDigest, value: Double) -> Double
    }

    final class PercentPendingGoalDigestAdjuster: PendingGoalDigestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingGoalDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitlePendingGoalDigestAdjuster: PendingGoalDigestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: PendingGoalDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedPendingGoalDigestAdjuster: PendingGoalDigestAdjuster {
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

        func adjust(_ item: PendingGoalDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending goal digest steps in order and keeps a trace of each.
    final class PendingGoalDigestEngine {
        var steps: [any PendingGoalDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingGoalDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingGoalDigest) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingGoalDigestAdjuster = steps[index]
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

        func evaluateAll(_ items: [PendingGoalDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingGoalDigestEngine(_ flags: Kit.Flags.Registry) -> PendingGoalDigestEngine {
        return PendingGoalDigestEngine(
            steps: [
                PercentPendingGoalDigestAdjuster(percent: 12.1),
                TitlePendingGoalDigestAdjuster(factors: ["central": 1.22, "west": 1.36, "retail": 1.36]),
                FlaggedPendingGoalDigestAdjuster(flags: flags, flag: "pending-goal-digest-default", percent: -8.6),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 4008.5
        )
    }
}
