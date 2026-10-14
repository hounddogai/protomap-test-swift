import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool baseline calculation.
    protocol FloatPoolBaselineModifier {
        func describe() -> String
        func adjust(_ item: FloatPoolBaseline, value: Double) -> Double
    }

    final class MinimumFloatPoolBaselineAdjuster: FloatPoolBaselineModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FloatPoolBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingFloatPoolBaselineAdjuster: FloatPoolBaselineModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FloatPoolBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentFloatPoolBaselineAdjuster: FloatPoolBaselineModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FloatPoolBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SegmentFloatPoolBaselineAdjuster: FloatPoolBaselineModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: FloatPoolBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredFloatPoolBaselineAdjuster: FloatPoolBaselineModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FloatPoolBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the float pool baseline steps in order and keeps a trace of each.
    final class FloatPoolBaselineEngine {
        var steps: [any FloatPoolBaselineModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolBaselineModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FloatPoolBaseline) -> Double {
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

        func evaluateAll(_ items: [FloatPoolBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFloatPoolBaselineEngine() -> FloatPoolBaselineEngine {
        return FloatPoolBaselineEngine(
            steps: [
                MinimumFloatPoolBaselineAdjuster(minimum: 31.4),
                RoundingFloatPoolBaselineAdjuster(step: 1.0),
                PercentFloatPoolBaselineAdjuster(percent: -21.8),
                SegmentFloatPoolBaselineAdjuster(factors: ["east": 0.98, "central": 0.73, "west": 1.09]),
                TieredFloatPoolBaselineAdjuster(bounds: [4067.0, 8501.0], rates: [1.08, 1.04]),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 61902.1
        )
    }
}
