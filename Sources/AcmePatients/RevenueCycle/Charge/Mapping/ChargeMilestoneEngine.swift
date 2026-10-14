import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge milestone calculation.
    protocol ChargeMilestoneFactor {
        func describe() -> String
        func adjust(_ item: ChargeMilestone, value: Double) -> Double
    }

    final class ChargeMilestoneThresholdOffsetAdjuster: ChargeMilestoneFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: ChargeMilestone, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class MinimumChargeMilestoneAdjuster: ChargeMilestoneFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ChargeMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredChargeMilestoneAdjuster: ChargeMilestoneFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ChargeMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedChargeMilestoneAdjuster: ChargeMilestoneFactor {
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

        func adjust(_ item: ChargeMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingChargeMilestoneAdjuster: ChargeMilestoneFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ChargeMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the charge milestone steps in order and keeps a trace of each.
    final class ChargeMilestoneEngine {
        var steps: [any ChargeMilestoneFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeMilestoneFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ChargeMilestone) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [ChargeMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultChargeMilestoneEngine(_ flags: Kit.Flags.Registry) -> ChargeMilestoneEngine {
        return ChargeMilestoneEngine(
            steps: [
                ChargeMilestoneThresholdOffsetAdjuster(weight: 1.55),
                MinimumChargeMilestoneAdjuster(minimum: 39.8),
                TieredChargeMilestoneAdjuster(
                    bounds: [1556.0, 3125.0, 7718.0, 9370.0],
                    rates: [1.19, 0.84, 1.0, 0.83]
                ),
                FlaggedChargeMilestoneAdjuster(flags: flags, flag: "charge-milestone-default", percent: 9.0),
                RoundingChargeMilestoneAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 8064.9
        )
    }
}
