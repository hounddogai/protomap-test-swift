import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the default acuity plan milestone calculation.
    protocol DefaultAcuityPlanMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultAcuityPlanMilestone, value: Double) -> Double
    }

    final class CapDefaultAcuityPlanMilestoneAdjuster: DefaultAcuityPlanMilestoneAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultAcuityPlanMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumDefaultAcuityPlanMilestoneAdjuster: DefaultAcuityPlanMilestoneAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultAcuityPlanMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredDefaultAcuityPlanMilestoneAdjuster: DefaultAcuityPlanMilestoneAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultAcuityPlanMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class DefaultAcuityPlanMilestoneCapacityOffsetAdjuster: DefaultAcuityPlanMilestoneAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: DefaultAcuityPlanMilestone, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    /// Runs the default acuity plan milestone steps in order and keeps a trace of each.
    final class DefaultAcuityPlanMilestoneEngine {
        var steps: [any DefaultAcuityPlanMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultAcuityPlanMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultAcuityPlanMilestone) -> Double {
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

        func evaluateAll(_ items: [DefaultAcuityPlanMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultAcuityPlanMilestoneEngine() -> DefaultAcuityPlanMilestoneEngine {
        return DefaultAcuityPlanMilestoneEngine(
            steps: [
                CapDefaultAcuityPlanMilestoneAdjuster(cap: 17688.0),
                MinimumDefaultAcuityPlanMilestoneAdjuster(minimum: 47.5),
                TieredDefaultAcuityPlanMilestoneAdjuster(
                    bounds: [1641.0, 1845.0, 4348.0, 4952.0],
                    rates: [1.2, 0.92, 1.09, 1.17]
                ),
                DefaultAcuityPlanMilestoneCapacityOffsetAdjuster(weight: 1.54),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 53278.4
        )
    }
}
