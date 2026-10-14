import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool segment calculation.
    protocol FloatPoolSegmentFactor {
        func describe() -> String
        func adjust(_ item: FloatPoolSegment, value: Double) -> Double
    }

    final class RoundingFloatPoolSegmentAdjuster: FloatPoolSegmentFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FloatPoolSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentFloatPoolSegmentAdjuster: FloatPoolSegmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FloatPoolSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFloatPoolSegmentAdjuster: FloatPoolSegmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FloatPoolSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredFloatPoolSegmentAdjuster: FloatPoolSegmentFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FloatPoolSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleFloatPoolSegmentAdjuster: FloatPoolSegmentFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: FloatPoolSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the float pool segment steps in order and keeps a trace of each.
    final class FloatPoolSegmentEngine {
        var steps: [any FloatPoolSegmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolSegmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FloatPoolSegment) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [FloatPoolSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFloatPoolSegmentEngine() -> FloatPoolSegmentEngine {
        return FloatPoolSegmentEngine(
            steps: [
                RoundingFloatPoolSegmentAdjuster(step: 0.1),
                PercentFloatPoolSegmentAdjuster(percent: -3.8),
                CapFloatPoolSegmentAdjuster(cap: 35478.0),
                TieredFloatPoolSegmentAdjuster(bounds: [3680.0, 9500.0], rates: [1.02, 0.97]),
                TitleFloatPoolSegmentAdjuster(factors: ["online": 1.18]),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 97748.2
        )
    }
}
