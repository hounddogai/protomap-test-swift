import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the discharge plan milestone calculation.
    protocol DischargePlanMilestoneStep {
        func describe() -> String
        func adjust(_ item: DischargePlanMilestone, value: Double) -> Double
    }

    final class RoundingDischargePlanMilestoneAdjuster: DischargePlanMilestoneStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DischargePlanMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredDischargePlanMilestoneAdjuster: DischargePlanMilestoneStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DischargePlanMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleDischargePlanMilestoneAdjuster: DischargePlanMilestoneStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: DischargePlanMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapDischargePlanMilestoneAdjuster: DischargePlanMilestoneStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DischargePlanMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the discharge plan milestone steps in order and keeps a trace of each.
    final class DischargePlanMilestoneEngine {
        var steps: [any DischargePlanMilestoneStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DischargePlanMilestoneStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DischargePlanMilestone) -> Double {
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

        func evaluateAll(_ items: [DischargePlanMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDischargePlanMilestoneEngine() -> DischargePlanMilestoneEngine {
        return DischargePlanMilestoneEngine(
            steps: [
                RoundingDischargePlanMilestoneAdjuster(step: 1.0),
                TieredDischargePlanMilestoneAdjuster(bounds: [210.0, 2414.0, 8271.0], rates: [1.04, 0.93, 0.85]),
                TitleDischargePlanMilestoneAdjuster(factors: ["south": 1.05]),
                CapDischargePlanMilestoneAdjuster(cap: 3210.0),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 11592.4
        )
    }
}
