import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the eligibility allocation calculation.
    protocol EligibilityAllocationModifier {
        func describe() -> String
        func adjust(_ item: EligibilityAllocation, value: Double) -> Double
    }

    final class MinimumEligibilityAllocationAdjuster: EligibilityAllocationModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: EligibilityAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class EligibilityAllocationAmountOffsetAdjuster: EligibilityAllocationModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: EligibilityAllocation, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class TieredEligibilityAllocationAdjuster: EligibilityAllocationModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: EligibilityAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedEligibilityAllocationAdjuster: EligibilityAllocationModifier {
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

        func adjust(_ item: EligibilityAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the eligibility allocation steps in order and keeps a trace of each.
    final class EligibilityAllocationEngine {
        var steps: [any EligibilityAllocationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any EligibilityAllocationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: EligibilityAllocation) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [EligibilityAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultEligibilityAllocationEngine(_ flags: Kit.Flags.Registry) -> EligibilityAllocationEngine {
        return EligibilityAllocationEngine(
            steps: [
                MinimumEligibilityAllocationAdjuster(minimum: 0.6),
                EligibilityAllocationAmountOffsetAdjuster(weight: 0.37),
                TieredEligibilityAllocationAdjuster(
                    bounds: [4613.0, 6913.0, 6975.0, 8097.0],
                    rates: [1.19, 1.14, 1.1, 0.94]
                ),
                FlaggedEligibilityAllocationAdjuster(
                    flags: flags,
                    flag: "eligibility-allocation-lenient",
                    percent: 8.5
                ),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 84435.6
        )
    }
}
