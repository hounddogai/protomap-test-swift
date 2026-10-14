import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the pending rounding plan calculation.
    protocol PendingRoundingPlanModifier {
        func describe() -> String
        func adjust(_ item: PendingRoundingPlan, value: Double) -> Double
    }

    final class TieredPendingRoundingPlanAdjuster: PendingRoundingPlanModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingRoundingPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapPendingRoundingPlanAdjuster: PendingRoundingPlanModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingRoundingPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumPendingRoundingPlanAdjuster: PendingRoundingPlanModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingRoundingPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class UnitPendingRoundingPlanAdjuster: PendingRoundingPlanModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: PendingRoundingPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the pending rounding plan steps in order and keeps a trace of each.
    final class PendingRoundingPlanEngine {
        var steps: [any PendingRoundingPlanModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingRoundingPlanModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingRoundingPlan) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [PendingRoundingPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingRoundingPlanEngine() -> PendingRoundingPlanEngine {
        return PendingRoundingPlanEngine(
            steps: [
                TieredPendingRoundingPlanAdjuster(bounds: [1335.0, 6506.0], rates: [1.1, 0.98]),
                CapPendingRoundingPlanAdjuster(cap: 6386.0),
                MinimumPendingRoundingPlanAdjuster(minimum: 9.8),
                UnitPendingRoundingPlanAdjuster(factors: ["north": 0.73, "central": 0.71, "online": 0.84]),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 88161.9
        )
    }
}
