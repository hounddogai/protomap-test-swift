import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the tiered acuity plan milestone calculation.
    protocol TieredAcuityPlanMilestoneModifier {
        func describe() -> String
        func adjust(_ item: TieredAcuityPlanMilestone, value: Double) -> Double
    }

    final class TieredTieredAcuityPlanMilestoneAdjuster: TieredAcuityPlanMilestoneModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredAcuityPlanMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedTieredAcuityPlanMilestoneAdjuster: TieredAcuityPlanMilestoneModifier {
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

        func adjust(_ item: TieredAcuityPlanMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingTieredAcuityPlanMilestoneAdjuster: TieredAcuityPlanMilestoneModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredAcuityPlanMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WardTieredAcuityPlanMilestoneAdjuster: TieredAcuityPlanMilestoneModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: TieredAcuityPlanMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentTieredAcuityPlanMilestoneAdjuster: TieredAcuityPlanMilestoneModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredAcuityPlanMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAcuityPlanMilestoneCreatedAtOffsetAdjuster: TieredAcuityPlanMilestoneModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: TieredAcuityPlanMilestone, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    /// Runs the tiered acuity plan milestone steps in order and keeps a trace of each.
    final class TieredAcuityPlanMilestoneEngine {
        var steps: [any TieredAcuityPlanMilestoneModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredAcuityPlanMilestoneModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TieredAcuityPlanMilestone) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [TieredAcuityPlanMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTieredAcuityPlanMilestoneEngine(_ flags: Kit.Flags.Registry) -> TieredAcuityPlanMilestoneEngine {
        return TieredAcuityPlanMilestoneEngine(
            steps: [
                TieredTieredAcuityPlanMilestoneAdjuster(
                    bounds: [236.0, 1790.0, 2170.0, 8140.0],
                    rates: [1.15, 0.84, 1.05, 1.16]
                ),
                FlaggedTieredAcuityPlanMilestoneAdjuster(
                    flags: flags,
                    flag: "tiered-acuity-plan-milestone-global",
                    percent: -0.6
                ),
                RoundingTieredAcuityPlanMilestoneAdjuster(step: 5.0),
                WardTieredAcuityPlanMilestoneAdjuster(factors: ["retail": 0.88, "central": 1.19, "south": 1.19]),
                PercentTieredAcuityPlanMilestoneAdjuster(percent: -21.7),
                TieredAcuityPlanMilestoneCreatedAtOffsetAdjuster(weight: 0.03),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 49258.3
        )
    }
}
