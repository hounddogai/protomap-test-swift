import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the adaptive read milestone calculation.
    protocol AdaptiveReadMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveReadMilestone, value: Double) -> Double
    }

    final class SegmentAdaptiveReadMilestoneAdjuster: AdaptiveReadMilestoneAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: AdaptiveReadMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapAdaptiveReadMilestoneAdjuster: AdaptiveReadMilestoneAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveReadMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingAdaptiveReadMilestoneAdjuster: AdaptiveReadMilestoneAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveReadMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumAdaptiveReadMilestoneAdjuster: AdaptiveReadMilestoneAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveReadMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedAdaptiveReadMilestoneAdjuster: AdaptiveReadMilestoneAdjuster {
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

        func adjust(_ item: AdaptiveReadMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive read milestone steps in order and keeps a trace of each.
    final class AdaptiveReadMilestoneEngine {
        var steps: [any AdaptiveReadMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveReadMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveReadMilestone) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [AdaptiveReadMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveReadMilestoneEngine(_ flags: Kit.Flags.Registry) -> AdaptiveReadMilestoneEngine {
        return AdaptiveReadMilestoneEngine(
            steps: [
                SegmentAdaptiveReadMilestoneAdjuster(factors: ["central": 0.8, "north": 0.87]),
                CapAdaptiveReadMilestoneAdjuster(cap: 6464.0),
                RoundingAdaptiveReadMilestoneAdjuster(step: 0.1),
                MinimumAdaptiveReadMilestoneAdjuster(minimum: 17.3),
                FlaggedAdaptiveReadMilestoneAdjuster(
                    flags: flags,
                    flag: "adaptive-read-milestone-capped",
                    percent: 2.4
                ),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 7621.4
        )
    }
}
