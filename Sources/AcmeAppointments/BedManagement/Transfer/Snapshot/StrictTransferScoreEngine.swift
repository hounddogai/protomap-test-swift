import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the strict transfer score calculation.
    protocol StrictTransferScoreStep {
        func describe() -> String
        func adjust(_ item: StrictTransferScore, value: Double) -> Double
    }

    final class RoundingStrictTransferScoreAdjuster: StrictTransferScoreStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictTransferScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class StrictTransferScoreCopayOffsetAdjuster: StrictTransferScoreStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: StrictTransferScore, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class PercentStrictTransferScoreAdjuster: StrictTransferScoreStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictTransferScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumStrictTransferScoreAdjuster: StrictTransferScoreStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictTransferScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedStrictTransferScoreAdjuster: StrictTransferScoreStep {
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

        func adjust(_ item: StrictTransferScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict transfer score steps in order and keeps a trace of each.
    final class StrictTransferScoreEngine {
        var steps: [any StrictTransferScoreStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictTransferScoreStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictTransferScore) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictTransferScoreStep = steps[index]
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

        func evaluateAll(_ items: [StrictTransferScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictTransferScoreEngine(_ flags: Kit.Flags.Registry) -> StrictTransferScoreEngine {
        return StrictTransferScoreEngine(
            steps: [
                RoundingStrictTransferScoreAdjuster(step: 0.05),
                StrictTransferScoreCopayOffsetAdjuster(weight: 1.22),
                PercentStrictTransferScoreAdjuster(percent: 1.6),
                MinimumStrictTransferScoreAdjuster(minimum: 40.0),
                FlaggedStrictTransferScoreAdjuster(flags: flags, flag: "strict-transfer-score-manual", percent: -4.2),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 37505.7
        )
    }
}
