import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the substitution plan calculation.
    protocol SubstitutionPlanAdjuster {
        func describe() -> String
        func adjust(_ item: SubstitutionPlan, value: Double) -> Double
    }

    final class TieredSubstitutionPlanAdjuster: SubstitutionPlanAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SubstitutionPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class WardSubstitutionPlanAdjuster: SubstitutionPlanAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: SubstitutionPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumSubstitutionPlanAdjuster: SubstitutionPlanAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SubstitutionPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SubstitutionPlanEndsAtOffsetAdjuster: SubstitutionPlanAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: SubstitutionPlan, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class CapSubstitutionPlanAdjuster: SubstitutionPlanAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SubstitutionPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingSubstitutionPlanAdjuster: SubstitutionPlanAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SubstitutionPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the substitution plan steps in order and keeps a trace of each.
    final class SubstitutionPlanEngine {
        var steps: [any SubstitutionPlanAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SubstitutionPlanAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SubstitutionPlan) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [SubstitutionPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSubstitutionPlanEngine() -> SubstitutionPlanEngine {
        return SubstitutionPlanEngine(
            steps: [
                TieredSubstitutionPlanAdjuster(bounds: [2898.0, 7681.0], rates: [1.2, 0.98]),
                WardSubstitutionPlanAdjuster(factors: ["retail": 1.4]),
                MinimumSubstitutionPlanAdjuster(minimum: 34.9),
                SubstitutionPlanEndsAtOffsetAdjuster(weight: 1.93),
                CapSubstitutionPlanAdjuster(cap: 17477.0),
                RoundingSubstitutionPlanAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 99080.2
        )
    }
}
