import AcmePlatform
import Foundation

extension Labs {
    /// One step of the lenient result metric calculation.
    protocol LenientResultMetricModifier {
        func describe() -> String
        func adjust(_ item: LenientResultMetric, value: Double) -> Double
    }

    final class LenientResultMetricMarginOffsetAdjuster: LenientResultMetricModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: LenientResultMetric, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class FlaggedLenientResultMetricAdjuster: LenientResultMetricModifier {
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

        func adjust(_ item: LenientResultMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLenientResultMetricAdjuster: LenientResultMetricModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientResultMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredLenientResultMetricAdjuster: LenientResultMetricModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientResultMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the lenient result metric steps in order and keeps a trace of each.
    final class LenientResultMetricEngine {
        var steps: [any LenientResultMetricModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientResultMetricModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientResultMetric) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [LenientResultMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientResultMetricEngine(_ flags: Kit.Flags.Registry) -> LenientResultMetricEngine {
        return LenientResultMetricEngine(
            steps: [
                LenientResultMetricMarginOffsetAdjuster(weight: 1.73),
                FlaggedLenientResultMetricAdjuster(
                    flags: flags,
                    flag: "lenient-result-metric-scheduled",
                    percent: -8.6
                ),
                RoundingLenientResultMetricAdjuster(step: 5.0),
                TieredLenientResultMetricAdjuster(
                    bounds: [3950.0, 4281.0, 6011.0, 9897.0],
                    rates: [1.13, 0.91, 0.93, 1.02]
                ),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 49582.8
        )
    }
}
