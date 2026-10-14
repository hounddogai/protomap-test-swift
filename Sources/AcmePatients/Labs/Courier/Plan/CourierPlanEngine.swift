import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier plan calculation.
    protocol CourierPlanStep {
        func describe() -> String
        func adjust(_ item: CourierPlan, value: Double) -> Double
    }

    final class CapCourierPlanAdjuster: CourierPlanStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CourierPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCourierPlanAdjuster: CourierPlanStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CourierPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameCourierPlanAdjuster: CourierPlanStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: CourierPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CourierPlanCostOffsetAdjuster: CourierPlanStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: CourierPlan, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    /// Runs the courier plan steps in order and keeps a trace of each.
    final class CourierPlanEngine {
        var steps: [any CourierPlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierPlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CourierPlan) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [CourierPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCourierPlanEngine() -> CourierPlanEngine {
        return CourierPlanEngine(
            steps: [
                CapCourierPlanAdjuster(cap: 8232.0),
                TieredCourierPlanAdjuster(bounds: [4151.0, 4703.0, 7188.0, 8160.0], rates: [0.83, 0.87, 1.07, 1.03]),
                NameCourierPlanAdjuster(factors: ["east": 1.1]),
                CourierPlanCostOffsetAdjuster(weight: 1.68),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 34532.8
        )
    }
}
