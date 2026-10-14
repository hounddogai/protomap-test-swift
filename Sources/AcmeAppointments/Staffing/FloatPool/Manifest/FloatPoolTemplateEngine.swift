import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool template calculation.
    protocol FloatPoolTemplateModifier {
        func describe() -> String
        func adjust(_ item: FloatPoolTemplate, value: Double) -> Double
    }

    final class CapFloatPoolTemplateAdjuster: FloatPoolTemplateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FloatPoolTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingFloatPoolTemplateAdjuster: FloatPoolTemplateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FloatPoolTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredFloatPoolTemplateAdjuster: FloatPoolTemplateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FloatPoolTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SegmentFloatPoolTemplateAdjuster: FloatPoolTemplateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: FloatPoolTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumFloatPoolTemplateAdjuster: FloatPoolTemplateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FloatPoolTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentFloatPoolTemplateAdjuster: FloatPoolTemplateModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FloatPoolTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the float pool template steps in order and keeps a trace of each.
    final class FloatPoolTemplateEngine {
        var steps: [any FloatPoolTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FloatPoolTemplate) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [FloatPoolTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFloatPoolTemplateEngine() -> FloatPoolTemplateEngine {
        return FloatPoolTemplateEngine(
            steps: [
                CapFloatPoolTemplateAdjuster(cap: 36418.0),
                RoundingFloatPoolTemplateAdjuster(step: 0.1),
                TieredFloatPoolTemplateAdjuster(
                    bounds: [562.0, 2696.0, 2715.0, 9400.0],
                    rates: [1.16, 0.83, 1.15, 0.93]
                ),
                SegmentFloatPoolTemplateAdjuster(factors: ["north": 1.0]),
                MinimumFloatPoolTemplateAdjuster(minimum: 50.0),
                PercentFloatPoolTemplateAdjuster(percent: 10.6),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 54560.2
        )
    }
}
