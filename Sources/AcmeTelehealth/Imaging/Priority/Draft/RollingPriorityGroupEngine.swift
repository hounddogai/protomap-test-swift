import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the rolling priority group calculation.
    protocol RollingPriorityGroupStep {
        func describe() -> String
        func adjust(_ item: RollingPriorityGroup, value: Double) -> Double
    }

    final class RoundingRollingPriorityGroupAdjuster: RollingPriorityGroupStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingPriorityGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRollingPriorityGroupAdjuster: RollingPriorityGroupStep {
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

        func adjust(_ item: RollingPriorityGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRollingPriorityGroupAdjuster: RollingPriorityGroupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingPriorityGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentRollingPriorityGroupAdjuster: RollingPriorityGroupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingPriorityGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RollingPriorityGroupWeightOffsetAdjuster: RollingPriorityGroupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: RollingPriorityGroup, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class TitleRollingPriorityGroupAdjuster: RollingPriorityGroupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RollingPriorityGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the rolling priority group steps in order and keeps a trace of each.
    final class RollingPriorityGroupEngine {
        var steps: [any RollingPriorityGroupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingPriorityGroupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RollingPriorityGroup) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [RollingPriorityGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRollingPriorityGroupEngine(_ flags: Kit.Flags.Registry) -> RollingPriorityGroupEngine {
        return RollingPriorityGroupEngine(
            steps: [
                RoundingRollingPriorityGroupAdjuster(step: 0.25),
                FlaggedRollingPriorityGroupAdjuster(
                    flags: flags,
                    flag: "rolling-priority-group-regional",
                    percent: -5.0
                ),
                TieredRollingPriorityGroupAdjuster(bounds: [1702.0, 6652.0, 9151.0], rates: [1.02, 0.85, 1.03]),
                PercentRollingPriorityGroupAdjuster(percent: 20.2),
                RollingPriorityGroupWeightOffsetAdjuster(weight: 1.55),
                TitleRollingPriorityGroupAdjuster(factors: ["retail": 0.84, "west": 1.06]),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 70246.8
        )
    }
}
