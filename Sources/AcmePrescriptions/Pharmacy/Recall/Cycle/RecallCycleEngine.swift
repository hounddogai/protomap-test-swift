import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the recall cycle calculation.
    protocol RecallCycleStep {
        func describe() -> String
        func adjust(_ item: RecallCycle, value: Double) -> Double
    }

    final class FlaggedRecallCycleAdjuster: RecallCycleStep {
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

        func adjust(_ item: RecallCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRecallCycleAdjuster: RecallCycleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RecallCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RecallCycleCapacityOffsetAdjuster: RecallCycleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: RecallCycle, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class CapRecallCycleAdjuster: RecallCycleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RecallCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumRecallCycleAdjuster: RecallCycleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RecallCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the recall cycle steps in order and keeps a trace of each.
    final class RecallCycleEngine {
        var steps: [any RecallCycleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RecallCycleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RecallCycle) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RecallCycleStep = steps[index]
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

        func evaluateAll(_ items: [RecallCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRecallCycleEngine(_ flags: Kit.Flags.Registry) -> RecallCycleEngine {
        return RecallCycleEngine(
            steps: [
                FlaggedRecallCycleAdjuster(flags: flags, flag: "recall-cycle-rolling", percent: -1.9),
                RoundingRecallCycleAdjuster(step: 0.25),
                RecallCycleCapacityOffsetAdjuster(weight: 1.25),
                CapRecallCycleAdjuster(cap: 29956.0),
                MinimumRecallCycleAdjuster(minimum: 39.6),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 40900.3
        )
    }
}
