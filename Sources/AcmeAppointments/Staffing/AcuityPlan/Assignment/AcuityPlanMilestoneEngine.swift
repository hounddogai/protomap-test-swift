import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan milestone calculation.
    protocol AcuityPlanMilestoneFactor {
        func describe() -> String
        func adjust(_ item: AcuityPlanMilestone, value: Double) -> Double
    }

    final class CapAcuityPlanMilestoneAdjuster: AcuityPlanMilestoneFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AcuityPlanMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelAcuityPlanMilestoneAdjuster: AcuityPlanMilestoneFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: AcuityPlanMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredAcuityPlanMilestoneAdjuster: AcuityPlanMilestoneFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AcuityPlanMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAcuityPlanMilestoneAdjuster: AcuityPlanMilestoneFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AcuityPlanMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the acuity plan milestone steps in order and keeps a trace of each.
    final class AcuityPlanMilestoneEngine {
        var steps: [any AcuityPlanMilestoneFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanMilestoneFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AcuityPlanMilestone) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [AcuityPlanMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanMilestoneEngine() -> AcuityPlanMilestoneEngine {
        return AcuityPlanMilestoneEngine(
            steps: [
                CapAcuityPlanMilestoneAdjuster(cap: 39695.0),
                LabelAcuityPlanMilestoneAdjuster(factors: ["north": 1.07, "east": 1.05, "south": 0.78]),
                TieredAcuityPlanMilestoneAdjuster(bounds: [2701.0, 7537.0], rates: [1.14, 0.85]),
                MinimumAcuityPlanMilestoneAdjuster(minimum: 38.7),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 14909.1
        )
    }
}
