import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool request calculation.
    protocol FloatPoolRequestModifier {
        func describe() -> String
        func adjust(_ item: FloatPoolRequest, value: Double) -> Double
    }

    final class RoundingFloatPoolRequestAdjuster: FloatPoolRequestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FloatPoolRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapFloatPoolRequestAdjuster: FloatPoolRequestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FloatPoolRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredFloatPoolRequestAdjuster: FloatPoolRequestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FloatPoolRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentFloatPoolRequestAdjuster: FloatPoolRequestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FloatPoolRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumFloatPoolRequestAdjuster: FloatPoolRequestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FloatPoolRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the float pool request steps in order and keeps a trace of each.
    final class FloatPoolRequestEngine {
        var steps: [any FloatPoolRequestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolRequestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FloatPoolRequest) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [FloatPoolRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFloatPoolRequestEngine() -> FloatPoolRequestEngine {
        return FloatPoolRequestEngine(
            steps: [
                RoundingFloatPoolRequestAdjuster(step: 0.5),
                CapFloatPoolRequestAdjuster(cap: 48176.0),
                TieredFloatPoolRequestAdjuster(
                    bounds: [3143.0, 4098.0, 7258.0, 7767.0],
                    rates: [1.1, 1.01, 0.86, 0.92]
                ),
                PercentFloatPoolRequestAdjuster(percent: -14.4),
                MinimumFloatPoolRequestAdjuster(minimum: 2.7),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 77094.2
        )
    }
}
