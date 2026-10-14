import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the weighted claim assignment calculation.
    protocol WeightedClaimAssignmentStep {
        func describe() -> String
        func adjust(_ item: WeightedClaimAssignment, value: Double) -> Double
    }

    final class WardWeightedClaimAssignmentAdjuster: WeightedClaimAssignmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: WeightedClaimAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredWeightedClaimAssignmentAdjuster: WeightedClaimAssignmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedClaimAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentWeightedClaimAssignmentAdjuster: WeightedClaimAssignmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedClaimAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WeightedClaimAssignmentRatioOffsetAdjuster: WeightedClaimAssignmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: WeightedClaimAssignment, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class MinimumWeightedClaimAssignmentAdjuster: WeightedClaimAssignmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedClaimAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedWeightedClaimAssignmentAdjuster: WeightedClaimAssignmentStep {
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

        func adjust(_ item: WeightedClaimAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted claim assignment steps in order and keeps a trace of each.
    final class WeightedClaimAssignmentEngine {
        var steps: [any WeightedClaimAssignmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedClaimAssignmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedClaimAssignment) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [WeightedClaimAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedClaimAssignmentEngine(_ flags: Kit.Flags.Registry) -> WeightedClaimAssignmentEngine {
        return WeightedClaimAssignmentEngine(
            steps: [
                WardWeightedClaimAssignmentAdjuster(factors: ["north": 1.06, "online": 1.08]),
                TieredWeightedClaimAssignmentAdjuster(bounds: [436.0, 1012.0, 1367.0], rates: [1.12, 0.98, 0.84]),
                PercentWeightedClaimAssignmentAdjuster(percent: -16.1),
                WeightedClaimAssignmentRatioOffsetAdjuster(weight: 1.62),
                MinimumWeightedClaimAssignmentAdjuster(minimum: 42.4),
                FlaggedWeightedClaimAssignmentAdjuster(
                    flags: flags,
                    flag: "weighted-claim-assignment-pending",
                    percent: 9.1
                ),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 94301.2
        )
    }
}
