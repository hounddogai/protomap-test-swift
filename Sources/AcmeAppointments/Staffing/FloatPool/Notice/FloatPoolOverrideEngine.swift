import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool override calculation.
    protocol FloatPoolOverrideFactor {
        func describe() -> String
        func adjust(_ item: FloatPoolOverride, value: Double) -> Double
    }

    final class MinimumFloatPoolOverrideAdjuster: FloatPoolOverrideFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FloatPoolOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredFloatPoolOverrideAdjuster: FloatPoolOverrideFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FloatPoolOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapFloatPoolOverrideAdjuster: FloatPoolOverrideFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FloatPoolOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FloatPoolOverrideCopayOffsetAdjuster: FloatPoolOverrideFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: FloatPoolOverride, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class PercentFloatPoolOverrideAdjuster: FloatPoolOverrideFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FloatPoolOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelFloatPoolOverrideAdjuster: FloatPoolOverrideFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: FloatPoolOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the float pool override steps in order and keeps a trace of each.
    final class FloatPoolOverrideEngine {
        var steps: [any FloatPoolOverrideFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolOverrideFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FloatPoolOverride) -> Double {
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

        func evaluateAll(_ items: [FloatPoolOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFloatPoolOverrideEngine() -> FloatPoolOverrideEngine {
        return FloatPoolOverrideEngine(
            steps: [
                MinimumFloatPoolOverrideAdjuster(minimum: 17.6),
                TieredFloatPoolOverrideAdjuster(bounds: [5264.0, 6027.0], rates: [0.96, 0.81]),
                CapFloatPoolOverrideAdjuster(cap: 46809.0),
                FloatPoolOverrideCopayOffsetAdjuster(weight: 0.5),
                PercentFloatPoolOverrideAdjuster(percent: -21.7),
                ChannelFloatPoolOverrideAdjuster(factors: ["south": 0.88]),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 57825.9
        )
    }
}
