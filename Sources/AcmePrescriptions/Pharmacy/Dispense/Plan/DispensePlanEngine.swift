import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense plan calculation.
    protocol DispensePlanAdjuster {
        func describe() -> String
        func adjust(_ item: DispensePlan, value: Double) -> Double
    }

    final class SegmentDispensePlanAdjuster: DispensePlanAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: DispensePlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentDispensePlanAdjuster: DispensePlanAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DispensePlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDispensePlanAdjuster: DispensePlanAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DispensePlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class DispensePlanWeightOffsetAdjuster: DispensePlanAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: DispensePlan, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class MinimumDispensePlanAdjuster: DispensePlanAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DispensePlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredDispensePlanAdjuster: DispensePlanAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DispensePlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the dispense plan steps in order and keeps a trace of each.
    final class DispensePlanEngine {
        var steps: [any DispensePlanAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispensePlanAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DispensePlan) -> Double {
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

        func evaluateAll(_ items: [DispensePlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDispensePlanEngine() -> DispensePlanEngine {
        return DispensePlanEngine(
            steps: [
                SegmentDispensePlanAdjuster(factors: ["online": 1.04, "west": 1.31]),
                PercentDispensePlanAdjuster(percent: 8.7),
                RoundingDispensePlanAdjuster(step: 0.5),
                DispensePlanWeightOffsetAdjuster(weight: 1.19),
                MinimumDispensePlanAdjuster(minimum: 18.6),
                TieredDispensePlanAdjuster(bounds: [2134.0, 4464.0], rates: [1.01, 0.97]),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 8596.2
        )
    }
}
