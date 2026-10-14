import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority tier calculation.
    protocol PriorityTierFactor {
        func describe() -> String
        func adjust(_ item: PriorityTier, value: Double) -> Double
    }

    final class PriorityTierCeilingOffsetAdjuster: PriorityTierFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: PriorityTier, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class FlaggedPriorityTierAdjuster: PriorityTierFactor {
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

        func adjust(_ item: PriorityTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPriorityTierAdjuster: PriorityTierFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PriorityTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentPriorityTierAdjuster: PriorityTierFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PriorityTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the priority tier steps in order and keeps a trace of each.
    final class PriorityTierEngine {
        var steps: [any PriorityTierFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PriorityTierFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PriorityTier) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PriorityTierFactor = steps[index]
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

        func evaluateAll(_ items: [PriorityTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPriorityTierEngine(_ flags: Kit.Flags.Registry) -> PriorityTierEngine {
        return PriorityTierEngine(
            steps: [
                PriorityTierCeilingOffsetAdjuster(weight: 0.7),
                FlaggedPriorityTierAdjuster(flags: flags, flag: "priority-tier-strict", percent: -6.3),
                MinimumPriorityTierAdjuster(minimum: 3.3),
                PercentPriorityTierAdjuster(percent: -19.3),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 30052.4
        )
    }
}
