import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the capped goal group calculation.
    protocol CappedGoalGroupModifier {
        func describe() -> String
        func adjust(_ item: CappedGoalGroup, value: Double) -> Double
    }

    final class CappedGoalGroupVisitMinutesOffsetAdjuster: CappedGoalGroupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: CappedGoalGroup, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class TieredCappedGoalGroupAdjuster: CappedGoalGroupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedGoalGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedCappedGoalGroupAdjuster: CappedGoalGroupModifier {
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

        func adjust(_ item: CappedGoalGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelCappedGoalGroupAdjuster: CappedGoalGroupModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: CappedGoalGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCappedGoalGroupAdjuster: CappedGoalGroupModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedGoalGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the capped goal group steps in order and keeps a trace of each.
    final class CappedGoalGroupEngine {
        var steps: [any CappedGoalGroupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedGoalGroupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedGoalGroup) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedGoalGroupModifier = steps[index]
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

        func evaluateAll(_ items: [CappedGoalGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedGoalGroupEngine(_ flags: Kit.Flags.Registry) -> CappedGoalGroupEngine {
        return CappedGoalGroupEngine(
            steps: [
                CappedGoalGroupVisitMinutesOffsetAdjuster(weight: 1.08),
                TieredCappedGoalGroupAdjuster(bounds: [1249.0, 4892.0, 5150.0], rates: [0.81, 1.14, 1.01]),
                FlaggedCappedGoalGroupAdjuster(flags: flags, flag: "capped-goal-group-fallback", percent: 0.7),
                ChannelCappedGoalGroupAdjuster(factors: ["online": 1.13, "south": 1.15]),
                RoundingCappedGoalGroupAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 15076.4
        )
    }
}
