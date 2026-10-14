import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the strict discharge plan policy calculation.
    protocol StrictDischargePlanPolicyAdjuster {
        func describe() -> String
        func adjust(_ item: StrictDischargePlanPolicy, value: Double) -> Double
    }

    final class SegmentStrictDischargePlanPolicyAdjuster: StrictDischargePlanPolicyAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: StrictDischargePlanPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentStrictDischargePlanPolicyAdjuster: StrictDischargePlanPolicyAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictDischargePlanPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class StrictDischargePlanPolicyMinimumOffsetAdjuster: StrictDischargePlanPolicyAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: StrictDischargePlanPolicy, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class MinimumStrictDischargePlanPolicyAdjuster: StrictDischargePlanPolicyAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictDischargePlanPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingStrictDischargePlanPolicyAdjuster: StrictDischargePlanPolicyAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictDischargePlanPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedStrictDischargePlanPolicyAdjuster: StrictDischargePlanPolicyAdjuster {
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

        func adjust(_ item: StrictDischargePlanPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict discharge plan policy steps in order and keeps a trace of each.
    final class StrictDischargePlanPolicyEngine {
        var steps: [any StrictDischargePlanPolicyAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictDischargePlanPolicyAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictDischargePlanPolicy) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [StrictDischargePlanPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictDischargePlanPolicyEngine(_ flags: Kit.Flags.Registry) -> StrictDischargePlanPolicyEngine {
        return StrictDischargePlanPolicyEngine(
            steps: [
                SegmentStrictDischargePlanPolicyAdjuster(factors: ["south": 0.95]),
                PercentStrictDischargePlanPolicyAdjuster(percent: 23.6),
                StrictDischargePlanPolicyMinimumOffsetAdjuster(weight: 0.62),
                MinimumStrictDischargePlanPolicyAdjuster(minimum: 8.0),
                RoundingStrictDischargePlanPolicyAdjuster(step: 5.0),
                FlaggedStrictDischargePlanPolicyAdjuster(
                    flags: flags,
                    flag: "strict-discharge-plan-policy-global",
                    percent: 5.8
                ),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 17348.2
        )
    }
}
