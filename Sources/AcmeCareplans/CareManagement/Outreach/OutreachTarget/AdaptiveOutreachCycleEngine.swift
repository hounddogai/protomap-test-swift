import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the adaptive outreach cycle calculation.
    protocol AdaptiveOutreachCycleModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveOutreachCycle, value: Double) -> Double
    }

    final class AdaptiveOutreachCycleUpdatedAtOffsetAdjuster: AdaptiveOutreachCycleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: AdaptiveOutreachCycle, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class CapAdaptiveOutreachCycleAdjuster: AdaptiveOutreachCycleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveOutreachCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentAdaptiveOutreachCycleAdjuster: AdaptiveOutreachCycleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveOutreachCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedAdaptiveOutreachCycleAdjuster: AdaptiveOutreachCycleModifier {
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

        func adjust(_ item: AdaptiveOutreachCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumAdaptiveOutreachCycleAdjuster: AdaptiveOutreachCycleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveOutreachCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the adaptive outreach cycle steps in order and keeps a trace of each.
    final class AdaptiveOutreachCycleEngine {
        var steps: [any AdaptiveOutreachCycleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveOutreachCycleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AdaptiveOutreachCycle) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveOutreachCycleModifier = steps[index]
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

        func evaluateAll(_ items: [AdaptiveOutreachCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAdaptiveOutreachCycleEngine(_ flags: Kit.Flags.Registry) -> AdaptiveOutreachCycleEngine {
        return AdaptiveOutreachCycleEngine(
            steps: [
                AdaptiveOutreachCycleUpdatedAtOffsetAdjuster(weight: 1.6),
                CapAdaptiveOutreachCycleAdjuster(cap: 8169.0),
                PercentAdaptiveOutreachCycleAdjuster(percent: 18.6),
                FlaggedAdaptiveOutreachCycleAdjuster(
                    flags: flags,
                    flag: "adaptive-outreach-cycle-batched",
                    percent: -7.5
                ),
                MinimumAdaptiveOutreachCycleAdjuster(minimum: 33.5),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 19096.3
        )
    }
}
