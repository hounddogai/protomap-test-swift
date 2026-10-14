import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the discharge plan claim calculation.
    protocol DischargePlanClaimAdjuster {
        func describe() -> String
        func adjust(_ item: DischargePlanClaim, value: Double) -> Double
    }

    final class DischargePlanClaimDiscountOffsetAdjuster: DischargePlanClaimAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: DischargePlanClaim, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class RoundingDischargePlanClaimAdjuster: DischargePlanClaimAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DischargePlanClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentDischargePlanClaimAdjuster: DischargePlanClaimAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DischargePlanClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDischargePlanClaimAdjuster: DischargePlanClaimAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DischargePlanClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedDischargePlanClaimAdjuster: DischargePlanClaimAdjuster {
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

        func adjust(_ item: DischargePlanClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapDischargePlanClaimAdjuster: DischargePlanClaimAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DischargePlanClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the discharge plan claim steps in order and keeps a trace of each.
    final class DischargePlanClaimEngine {
        var steps: [any DischargePlanClaimAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DischargePlanClaimAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DischargePlanClaim) -> Double {
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

        func evaluateAll(_ items: [DischargePlanClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDischargePlanClaimEngine(_ flags: Kit.Flags.Registry) -> DischargePlanClaimEngine {
        return DischargePlanClaimEngine(
            steps: [
                DischargePlanClaimDiscountOffsetAdjuster(weight: 0.32),
                RoundingDischargePlanClaimAdjuster(step: 0.25),
                PercentDischargePlanClaimAdjuster(percent: -10.1),
                MinimumDischargePlanClaimAdjuster(minimum: 1.3),
                FlaggedDischargePlanClaimAdjuster(flags: flags, flag: "discharge-plan-claim-strict", percent: -4.6),
                CapDischargePlanClaimAdjuster(cap: 15677.0),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 89903.1
        )
    }
}
