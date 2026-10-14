import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the primary recall plan calculation.
    protocol PrimaryRecallPlanFactor {
        func describe() -> String
        func adjust(_ item: PrimaryRecallPlan, value: Double) -> Double
    }

    final class CapPrimaryRecallPlanAdjuster: PrimaryRecallPlanFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryRecallPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RegionPrimaryRecallPlanAdjuster: PrimaryRecallPlanFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: PrimaryRecallPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredPrimaryRecallPlanAdjuster: PrimaryRecallPlanFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryRecallPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the primary recall plan steps in order and keeps a trace of each.
    final class PrimaryRecallPlanEngine {
        var steps: [any PrimaryRecallPlanFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryRecallPlanFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrimaryRecallPlan) -> Double {
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

        func evaluateAll(_ items: [PrimaryRecallPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrimaryRecallPlanEngine() -> PrimaryRecallPlanEngine {
        return PrimaryRecallPlanEngine(
            steps: [
                CapPrimaryRecallPlanAdjuster(cap: 21501.0),
                RegionPrimaryRecallPlanAdjuster(factors: ["north": 0.84]),
                TieredPrimaryRecallPlanAdjuster(bounds: [4277.0, 8762.0, 8930.0], rates: [0.86, 1.09, 0.83]),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 78370.4
        )
    }
}
