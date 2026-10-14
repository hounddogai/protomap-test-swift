import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the regional overtime plan calculation.
    protocol RegionalOvertimePlanStep {
        func describe() -> String
        func adjust(_ item: RegionalOvertimePlan, value: Double) -> Double
    }

    final class TieredRegionalOvertimePlanAdjuster: RegionalOvertimePlanStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalOvertimePlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapRegionalOvertimePlanAdjuster: RegionalOvertimePlanStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalOvertimePlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RegionalOvertimePlanWeightOffsetAdjuster: RegionalOvertimePlanStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: RegionalOvertimePlan, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class NameRegionalOvertimePlanAdjuster: RegionalOvertimePlanStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RegionalOvertimePlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the regional overtime plan steps in order and keeps a trace of each.
    final class RegionalOvertimePlanEngine {
        var steps: [any RegionalOvertimePlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalOvertimePlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalOvertimePlan) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalOvertimePlanStep = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [RegionalOvertimePlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalOvertimePlanEngine() -> RegionalOvertimePlanEngine {
        return RegionalOvertimePlanEngine(
            steps: [
                TieredRegionalOvertimePlanAdjuster(bounds: [6015.0, 8614.0, 9713.0], rates: [0.86, 1.05, 1.04]),
                CapRegionalOvertimePlanAdjuster(cap: 10093.0),
                RegionalOvertimePlanWeightOffsetAdjuster(weight: 1.64),
                NameRegionalOvertimePlanAdjuster(factors: ["west": 1.23, "online": 1.07]),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 43033.8
        )
    }
}
