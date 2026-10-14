import AcmePlatform
import Foundation

extension Consent {
    /// One step of the weighted revocation milestone calculation.
    protocol WeightedRevocationMilestoneStep {
        func describe() -> String
        func adjust(_ item: WeightedRevocationMilestone, value: Double) -> Double
    }

    final class WeightedRevocationMilestoneThresholdOffsetAdjuster: WeightedRevocationMilestoneStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: WeightedRevocationMilestone, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class TieredWeightedRevocationMilestoneAdjuster: WeightedRevocationMilestoneStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedRevocationMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentWeightedRevocationMilestoneAdjuster: WeightedRevocationMilestoneStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedRevocationMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumWeightedRevocationMilestoneAdjuster: WeightedRevocationMilestoneStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedRevocationMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedWeightedRevocationMilestoneAdjuster: WeightedRevocationMilestoneStep {
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

        func adjust(_ item: WeightedRevocationMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingWeightedRevocationMilestoneAdjuster: WeightedRevocationMilestoneStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedRevocationMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the weighted revocation milestone steps in order and keeps a trace of each.
    final class WeightedRevocationMilestoneEngine {
        var steps: [any WeightedRevocationMilestoneStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedRevocationMilestoneStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedRevocationMilestone) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [WeightedRevocationMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedRevocationMilestoneEngine(_ flags: Kit.Flags.Registry) -> WeightedRevocationMilestoneEngine {
        return WeightedRevocationMilestoneEngine(
            steps: [
                WeightedRevocationMilestoneThresholdOffsetAdjuster(weight: 0.71),
                TieredWeightedRevocationMilestoneAdjuster(
                    bounds: [1524.0, 2444.0, 2894.0, 4069.0],
                    rates: [0.87, 1.17, 1.02, 0.9]
                ),
                PercentWeightedRevocationMilestoneAdjuster(percent: 14.9),
                MinimumWeightedRevocationMilestoneAdjuster(minimum: 6.1),
                FlaggedWeightedRevocationMilestoneAdjuster(
                    flags: flags,
                    flag: "weighted-revocation-milestone-global",
                    percent: -7.8
                ),
                RoundingWeightedRevocationMilestoneAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 75412.1
        )
    }
}
