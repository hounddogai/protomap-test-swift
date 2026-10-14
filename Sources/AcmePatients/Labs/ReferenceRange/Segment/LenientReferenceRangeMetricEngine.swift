import AcmePlatform
import Foundation

extension Labs {
    /// One step of the lenient reference range metric calculation.
    protocol LenientReferenceRangeMetricAdjuster {
        func describe() -> String
        func adjust(_ item: LenientReferenceRangeMetric, value: Double) -> Double
    }

    final class MinimumLenientReferenceRangeMetricAdjuster: LenientReferenceRangeMetricAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientReferenceRangeMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredLenientReferenceRangeMetricAdjuster: LenientReferenceRangeMetricAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientReferenceRangeMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapLenientReferenceRangeMetricAdjuster: LenientReferenceRangeMetricAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientReferenceRangeMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleLenientReferenceRangeMetricAdjuster: LenientReferenceRangeMetricAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LenientReferenceRangeMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class LenientReferenceRangeMetricDiscountOffsetAdjuster: LenientReferenceRangeMetricAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: LenientReferenceRangeMetric, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    /// Runs the lenient reference range metric steps in order and keeps a trace of each.
    final class LenientReferenceRangeMetricEngine {
        var steps: [any LenientReferenceRangeMetricAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientReferenceRangeMetricAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientReferenceRangeMetric) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [LenientReferenceRangeMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientReferenceRangeMetricEngine() -> LenientReferenceRangeMetricEngine {
        return LenientReferenceRangeMetricEngine(
            steps: [
                MinimumLenientReferenceRangeMetricAdjuster(minimum: 45.8),
                TieredLenientReferenceRangeMetricAdjuster(bounds: [2076.0, 5545.0], rates: [1.1, 1.15]),
                CapLenientReferenceRangeMetricAdjuster(cap: 38429.0),
                TitleLenientReferenceRangeMetricAdjuster(factors: ["west": 1.12, "central": 0.81, "online": 0.79]),
                LenientReferenceRangeMetricDiscountOffsetAdjuster(weight: 1.27),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 57821.3
        )
    }
}
