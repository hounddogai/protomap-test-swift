import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the rolling closure profile calculation.
    protocol RollingClosureProfileStep {
        func describe() -> String
        func adjust(_ item: RollingClosureProfile, value: Double) -> Double
    }

    final class PercentRollingClosureProfileAdjuster: RollingClosureProfileStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingClosureProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RollingClosureProfileCostOffsetAdjuster: RollingClosureProfileStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: RollingClosureProfile, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class CapRollingClosureProfileAdjuster: RollingClosureProfileStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingClosureProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingRollingClosureProfileAdjuster: RollingClosureProfileStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingClosureProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WardRollingClosureProfileAdjuster: RollingClosureProfileStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: RollingClosureProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedRollingClosureProfileAdjuster: RollingClosureProfileStep {
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

        func adjust(_ item: RollingClosureProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rolling closure profile steps in order and keeps a trace of each.
    final class RollingClosureProfileEngine {
        var steps: [any RollingClosureProfileStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingClosureProfileStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingClosureProfile) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [RollingClosureProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingClosureProfileEngine(_ flags: Kit.Flags.Registry) -> RollingClosureProfileEngine {
        return RollingClosureProfileEngine(
            steps: [
                PercentRollingClosureProfileAdjuster(percent: 0.3),
                RollingClosureProfileCostOffsetAdjuster(weight: 0.22),
                CapRollingClosureProfileAdjuster(cap: 31440.0),
                RoundingRollingClosureProfileAdjuster(step: 0.5),
                WardRollingClosureProfileAdjuster(factors: ["central": 1.31, "north": 1.22]),
                FlaggedRollingClosureProfileAdjuster(
                    flags: flags,
                    flag: "rolling-closure-profile-global",
                    percent: -3.3
                ),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 38673.5
        )
    }
}
