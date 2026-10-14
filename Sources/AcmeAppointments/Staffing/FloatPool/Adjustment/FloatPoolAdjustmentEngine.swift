import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool adjustment calculation.
    protocol FloatPoolAdjustmentStep {
        func describe() -> String
        func adjust(_ item: FloatPoolAdjustment, value: Double) -> Double
    }

    final class RoundingFloatPoolAdjustmentAdjuster: FloatPoolAdjustmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FloatPoolAdjustment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredFloatPoolAdjustmentAdjuster: FloatPoolAdjustmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FloatPoolAdjustment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RegionFloatPoolAdjustmentAdjuster: FloatPoolAdjustmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: FloatPoolAdjustment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedFloatPoolAdjustmentAdjuster: FloatPoolAdjustmentStep {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: FloatPoolAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentFloatPoolAdjustmentAdjuster: FloatPoolAdjustmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FloatPoolAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the float pool adjustment steps in order and keeps a trace of each.
    final class FloatPoolAdjustmentEngine {
        var steps: [any FloatPoolAdjustmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolAdjustmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FloatPoolAdjustment) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any FloatPoolAdjustmentStep = steps[index]
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

        func evaluateAll(_ items: [FloatPoolAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFloatPoolAdjustmentEngine(_ flags: Kit.Flags.Registry) -> FloatPoolAdjustmentEngine {
        return FloatPoolAdjustmentEngine(
            steps: [
                RoundingFloatPoolAdjustmentAdjuster(step: 0.5),
                TieredFloatPoolAdjustmentAdjuster(
                    bounds: [425.0, 3831.0, 6626.0, 9671.0],
                    rates: [1.11, 0.86, 1.2, 1.09]
                ),
                RegionFloatPoolAdjustmentAdjuster(factors: ["south": 0.74, "east": 1.25, "online": 1.32]),
                FlaggedFloatPoolAdjustmentAdjuster(flags: flags, flag: "float-pool-adjustment-legacy", percent: 7.4),
                PercentFloatPoolAdjustmentAdjuster(percent: 19.3),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 30901.8
        )
    }
}
