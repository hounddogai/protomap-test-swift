import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the tiered overtime plan calculation.
    protocol TieredOvertimePlanModifier {
        func describe() -> String
        func adjust(_ item: TieredOvertimePlan, value: Double) -> Double
    }

    final class PercentTieredOvertimePlanAdjuster: TieredOvertimePlanModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredOvertimePlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumTieredOvertimePlanAdjuster: TieredOvertimePlanModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredOvertimePlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredOvertimePlanCapacityOffsetAdjuster: TieredOvertimePlanModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: TieredOvertimePlan, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class FlaggedTieredOvertimePlanAdjuster: TieredOvertimePlanModifier {
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

        func adjust(_ item: TieredOvertimePlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapTieredOvertimePlanAdjuster: TieredOvertimePlanModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredOvertimePlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the tiered overtime plan steps in order and keeps a trace of each.
    final class TieredOvertimePlanEngine {
        var steps: [any TieredOvertimePlanModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredOvertimePlanModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredOvertimePlan) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredOvertimePlanModifier = steps[index]
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

        func evaluateAll(_ items: [TieredOvertimePlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredOvertimePlanEngine(_ flags: Kit.Flags.Registry) -> TieredOvertimePlanEngine {
        return TieredOvertimePlanEngine(
            steps: [
                PercentTieredOvertimePlanAdjuster(percent: 22.5),
                MinimumTieredOvertimePlanAdjuster(minimum: 17.4),
                TieredOvertimePlanCapacityOffsetAdjuster(weight: 0.65),
                FlaggedTieredOvertimePlanAdjuster(flags: flags, flag: "tiered-overtime-plan-regional", percent: -3.7),
                CapTieredOvertimePlanAdjuster(cap: 5555.0),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 7871.0
        )
    }
}
