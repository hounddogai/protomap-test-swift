import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool variance calculation.
    protocol FloatPoolVarianceModifier {
        func describe() -> String
        func adjust(_ item: FloatPoolVariance, value: Double) -> Double
    }

    final class TieredFloatPoolVarianceAdjuster: FloatPoolVarianceModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FloatPoolVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedFloatPoolVarianceAdjuster: FloatPoolVarianceModifier {
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

        func adjust(_ item: FloatPoolVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentFloatPoolVarianceAdjuster: FloatPoolVarianceModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FloatPoolVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFloatPoolVarianceAdjuster: FloatPoolVarianceModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FloatPoolVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the float pool variance steps in order and keeps a trace of each.
    final class FloatPoolVarianceEngine {
        var steps: [any FloatPoolVarianceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolVarianceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FloatPoolVariance) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any FloatPoolVarianceModifier = steps[index]
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

        func evaluateAll(_ items: [FloatPoolVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFloatPoolVarianceEngine(_ flags: Kit.Flags.Registry) -> FloatPoolVarianceEngine {
        return FloatPoolVarianceEngine(
            steps: [
                TieredFloatPoolVarianceAdjuster(
                    bounds: [1378.0, 5973.0, 7380.0, 9201.0],
                    rates: [0.84, 1.02, 1.06, 0.86]
                ),
                FlaggedFloatPoolVarianceAdjuster(flags: flags, flag: "float-pool-variance-weighted", percent: -5.9),
                PercentFloatPoolVarianceAdjuster(percent: -9.9),
                RoundingFloatPoolVarianceAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 3380.5
        )
    }
}
