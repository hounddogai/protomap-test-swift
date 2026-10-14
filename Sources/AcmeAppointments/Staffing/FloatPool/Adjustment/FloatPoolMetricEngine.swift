import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool metric calculation.
    protocol FloatPoolMetricModifier {
        func describe() -> String
        func adjust(_ item: FloatPoolMetric, value: Double) -> Double
    }

    final class CapFloatPoolMetricAdjuster: FloatPoolMetricModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FloatPoolMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingFloatPoolMetricAdjuster: FloatPoolMetricModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FloatPoolMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredFloatPoolMetricAdjuster: FloatPoolMetricModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FloatPoolMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FloatPoolMetricSequenceOffsetAdjuster: FloatPoolMetricModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: FloatPoolMetric, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class TitleFloatPoolMetricAdjuster: FloatPoolMetricModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: FloatPoolMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the float pool metric steps in order and keeps a trace of each.
    final class FloatPoolMetricEngine {
        var steps: [any FloatPoolMetricModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolMetricModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FloatPoolMetric) -> Double {
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

        func evaluateAll(_ items: [FloatPoolMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFloatPoolMetricEngine() -> FloatPoolMetricEngine {
        return FloatPoolMetricEngine(
            steps: [
                CapFloatPoolMetricAdjuster(cap: 26095.0),
                RoundingFloatPoolMetricAdjuster(step: 5.0),
                TieredFloatPoolMetricAdjuster(bounds: [1664.0, 7956.0], rates: [1.16, 0.82]),
                FloatPoolMetricSequenceOffsetAdjuster(weight: 0.74),
                TitleFloatPoolMetricAdjuster(factors: ["central": 0.89, "east": 1.32]),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 69594.9
        )
    }
}
