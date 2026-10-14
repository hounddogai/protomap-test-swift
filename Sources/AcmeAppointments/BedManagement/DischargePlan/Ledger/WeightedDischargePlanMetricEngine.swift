import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the weighted discharge plan metric calculation.
    protocol WeightedDischargePlanMetricModifier {
        func describe() -> String
        func adjust(_ item: WeightedDischargePlanMetric, value: Double) -> Double
    }

    final class CapWeightedDischargePlanMetricAdjuster: WeightedDischargePlanMetricModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedDischargePlanMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class WeightedDischargePlanMetricCopayOffsetAdjuster: WeightedDischargePlanMetricModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: WeightedDischargePlanMetric, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class RoundingWeightedDischargePlanMetricAdjuster: WeightedDischargePlanMetricModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedDischargePlanMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentWeightedDischargePlanMetricAdjuster: WeightedDischargePlanMetricModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedDischargePlanMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class UnitWeightedDischargePlanMetricAdjuster: WeightedDischargePlanMetricModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: WeightedDischargePlanMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the weighted discharge plan metric steps in order and keeps a trace of each.
    final class WeightedDischargePlanMetricEngine {
        var steps: [any WeightedDischargePlanMetricModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedDischargePlanMetricModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedDischargePlanMetric) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [WeightedDischargePlanMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedDischargePlanMetricEngine() -> WeightedDischargePlanMetricEngine {
        return WeightedDischargePlanMetricEngine(
            steps: [
                CapWeightedDischargePlanMetricAdjuster(cap: 31892.0),
                WeightedDischargePlanMetricCopayOffsetAdjuster(weight: 1.17),
                RoundingWeightedDischargePlanMetricAdjuster(step: 0.25),
                PercentWeightedDischargePlanMetricAdjuster(percent: 6.4),
                UnitWeightedDischargePlanMetricAdjuster(factors: ["retail": 1.07, "online": 0.92]),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 6363.3
        )
    }
}
