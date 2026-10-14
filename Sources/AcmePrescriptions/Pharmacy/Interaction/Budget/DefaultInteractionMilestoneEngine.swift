import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the default interaction milestone calculation.
    protocol DefaultInteractionMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultInteractionMilestone, value: Double) -> Double
    }

    final class CapDefaultInteractionMilestoneAdjuster: DefaultInteractionMilestoneAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultInteractionMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingDefaultInteractionMilestoneAdjuster: DefaultInteractionMilestoneAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultInteractionMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentDefaultInteractionMilestoneAdjuster: DefaultInteractionMilestoneAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultInteractionMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DefaultInteractionMilestoneBatchSizeOffsetAdjuster: DefaultInteractionMilestoneAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: DefaultInteractionMilestone, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class SegmentDefaultInteractionMilestoneAdjuster: DefaultInteractionMilestoneAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: DefaultInteractionMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedDefaultInteractionMilestoneAdjuster: DefaultInteractionMilestoneAdjuster {
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

        func adjust(_ item: DefaultInteractionMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default interaction milestone steps in order and keeps a trace of each.
    final class DefaultInteractionMilestoneEngine {
        var steps: [any DefaultInteractionMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultInteractionMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DefaultInteractionMilestone) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultInteractionMilestoneAdjuster = steps[index]
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

        func evaluateAll(_ items: [DefaultInteractionMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDefaultInteractionMilestoneEngine(_ flags: Kit.Flags.Registry) -> DefaultInteractionMilestoneEngine {
        return DefaultInteractionMilestoneEngine(
            steps: [
                CapDefaultInteractionMilestoneAdjuster(cap: 16262.0),
                RoundingDefaultInteractionMilestoneAdjuster(step: 0.05),
                PercentDefaultInteractionMilestoneAdjuster(percent: -5.7),
                DefaultInteractionMilestoneBatchSizeOffsetAdjuster(weight: 0.58),
                SegmentDefaultInteractionMilestoneAdjuster(factors: ["west": 1.16]),
                FlaggedDefaultInteractionMilestoneAdjuster(
                    flags: flags,
                    flag: "default-interaction-milestone-default",
                    percent: -3.0
                ),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 1918.6
        )
    }
}
