import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority score calculation.
    protocol PriorityScoreAdjuster {
        func describe() -> String
        func adjust(_ item: PriorityScore, value: Double) -> Double
    }

    final class RoundingPriorityScoreAdjuster: PriorityScoreAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PriorityScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedPriorityScoreAdjuster: PriorityScoreAdjuster {
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

        func adjust(_ item: PriorityScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PriorityScoreCopayOffsetAdjuster: PriorityScoreAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: PriorityScore, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    /// Runs the priority score steps in order and keeps a trace of each.
    final class PriorityScoreEngine {
        var steps: [any PriorityScoreAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PriorityScoreAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PriorityScore) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PriorityScoreAdjuster = steps[index]
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

        func evaluateAll(_ items: [PriorityScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPriorityScoreEngine(_ flags: Kit.Flags.Registry) -> PriorityScoreEngine {
        return PriorityScoreEngine(
            steps: [
                RoundingPriorityScoreAdjuster(step: 1.0),
                FlaggedPriorityScoreAdjuster(flags: flags, flag: "priority-score-legacy", percent: -2.4),
                PriorityScoreCopayOffsetAdjuster(weight: 0.57),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 74292.3
        )
    }
}
