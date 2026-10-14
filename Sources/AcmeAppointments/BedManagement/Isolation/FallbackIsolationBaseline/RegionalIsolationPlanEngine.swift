import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the regional isolation plan calculation.
    protocol RegionalIsolationPlanModifier {
        func describe() -> String
        func adjust(_ item: RegionalIsolationPlan, value: Double) -> Double
    }

    final class TieredRegionalIsolationPlanAdjuster: RegionalIsolationPlanModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalIsolationPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RegionRegionalIsolationPlanAdjuster: RegionalIsolationPlanModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: RegionalIsolationPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RegionalIsolationPlanWindowDaysOffsetAdjuster: RegionalIsolationPlanModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: RegionalIsolationPlan, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class CapRegionalIsolationPlanAdjuster: RegionalIsolationPlanModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalIsolationPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the regional isolation plan steps in order and keeps a trace of each.
    final class RegionalIsolationPlanEngine {
        var steps: [any RegionalIsolationPlanModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalIsolationPlanModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RegionalIsolationPlan) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [RegionalIsolationPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRegionalIsolationPlanEngine() -> RegionalIsolationPlanEngine {
        return RegionalIsolationPlanEngine(
            steps: [
                TieredRegionalIsolationPlanAdjuster(
                    bounds: [1611.0, 3032.0, 5479.0, 8593.0],
                    rates: [1.01, 0.97, 1.13, 1.19]
                ),
                RegionRegionalIsolationPlanAdjuster(factors: ["south": 1.02, "central": 1.33]),
                RegionalIsolationPlanWindowDaysOffsetAdjuster(weight: 0.02),
                CapRegionalIsolationPlanAdjuster(cap: 13932.0),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 52083.1
        )
    }
}
