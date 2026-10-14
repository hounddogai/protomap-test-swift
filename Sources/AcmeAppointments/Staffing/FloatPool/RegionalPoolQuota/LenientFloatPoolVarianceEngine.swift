import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the lenient float pool variance calculation.
    protocol LenientFloatPoolVarianceModifier {
        func describe() -> String
        func adjust(_ item: LenientFloatPoolVariance, value: Double) -> Double
    }

    final class MinimumLenientFloatPoolVarianceAdjuster: LenientFloatPoolVarianceModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientFloatPoolVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLenientFloatPoolVarianceAdjuster: LenientFloatPoolVarianceModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientFloatPoolVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLenientFloatPoolVarianceAdjuster: LenientFloatPoolVarianceModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientFloatPoolVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LenientFloatPoolVarianceBudgetOffsetAdjuster: LenientFloatPoolVarianceModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: LenientFloatPoolVariance, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class RoundingLenientFloatPoolVarianceAdjuster: LenientFloatPoolVarianceModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientFloatPoolVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedLenientFloatPoolVarianceAdjuster: LenientFloatPoolVarianceModifier {
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

        func adjust(_ item: LenientFloatPoolVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient float pool variance steps in order and keeps a trace of each.
    final class LenientFloatPoolVarianceEngine {
        var steps: [any LenientFloatPoolVarianceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientFloatPoolVarianceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientFloatPoolVariance) -> Double {
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

        func evaluateAll(_ items: [LenientFloatPoolVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientFloatPoolVarianceEngine(_ flags: Kit.Flags.Registry) -> LenientFloatPoolVarianceEngine {
        return LenientFloatPoolVarianceEngine(
            steps: [
                MinimumLenientFloatPoolVarianceAdjuster(minimum: 48.5),
                PercentLenientFloatPoolVarianceAdjuster(percent: -15.9),
                TieredLenientFloatPoolVarianceAdjuster(bounds: [7385.0, 9358.0], rates: [0.83, 1.01]),
                LenientFloatPoolVarianceBudgetOffsetAdjuster(weight: 1.19),
                RoundingLenientFloatPoolVarianceAdjuster(step: 1.0),
                FlaggedLenientFloatPoolVarianceAdjuster(
                    flags: flags,
                    flag: "lenient-float-pool-variance-adaptive",
                    percent: 2.3
                ),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 50593.2
        )
    }
}
