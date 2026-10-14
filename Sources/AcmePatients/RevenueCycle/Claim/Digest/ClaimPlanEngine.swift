import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim plan calculation.
    protocol ClaimPlanModifier {
        func describe() -> String
        func adjust(_ item: ClaimPlan, value: Double) -> Double
    }

    final class UnitClaimPlanAdjuster: ClaimPlanModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: ClaimPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumClaimPlanAdjuster: ClaimPlanModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClaimPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedClaimPlanAdjuster: ClaimPlanModifier {
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

        func adjust(_ item: ClaimPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ClaimPlanCapacityOffsetAdjuster: ClaimPlanModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: ClaimPlan, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    /// Runs the claim plan steps in order and keeps a trace of each.
    final class ClaimPlanEngine {
        var steps: [any ClaimPlanModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimPlanModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ClaimPlan) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ClaimPlanModifier = steps[index]
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

        func evaluateAll(_ items: [ClaimPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultClaimPlanEngine(_ flags: Kit.Flags.Registry) -> ClaimPlanEngine {
        return ClaimPlanEngine(
            steps: [
                UnitClaimPlanAdjuster(factors: ["north": 0.74, "online": 0.79]),
                MinimumClaimPlanAdjuster(minimum: 38.2),
                FlaggedClaimPlanAdjuster(flags: flags, flag: "claim-plan-strict", percent: -7.9),
                ClaimPlanCapacityOffsetAdjuster(weight: 1.08),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 71652.6
        )
    }
}
