import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the lenient float pool estimate calculation.
    protocol LenientFloatPoolEstimateStep {
        func describe() -> String
        func adjust(_ item: LenientFloatPoolEstimate, value: Double) -> Double
    }

    final class PercentLenientFloatPoolEstimateAdjuster: LenientFloatPoolEstimateStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientFloatPoolEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLenientFloatPoolEstimateAdjuster: LenientFloatPoolEstimateStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientFloatPoolEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedLenientFloatPoolEstimateAdjuster: LenientFloatPoolEstimateStep {
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

        func adjust(_ item: LenientFloatPoolEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LenientFloatPoolEstimateThresholdOffsetAdjuster: LenientFloatPoolEstimateStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: LenientFloatPoolEstimate, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class RoundingLenientFloatPoolEstimateAdjuster: LenientFloatPoolEstimateStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientFloatPoolEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the lenient float pool estimate steps in order and keeps a trace of each.
    final class LenientFloatPoolEstimateEngine {
        var steps: [any LenientFloatPoolEstimateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientFloatPoolEstimateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientFloatPoolEstimate) -> Double {
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

        func evaluateAll(_ items: [LenientFloatPoolEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientFloatPoolEstimateEngine(_ flags: Kit.Flags.Registry) -> LenientFloatPoolEstimateEngine {
        return LenientFloatPoolEstimateEngine(
            steps: [
                PercentLenientFloatPoolEstimateAdjuster(percent: 13.9),
                TieredLenientFloatPoolEstimateAdjuster(bounds: [6641.0, 9049.0], rates: [1.02, 1.13]),
                FlaggedLenientFloatPoolEstimateAdjuster(
                    flags: flags,
                    flag: "lenient-float-pool-estimate-capped",
                    percent: 1.8
                ),
                LenientFloatPoolEstimateThresholdOffsetAdjuster(weight: 1.27),
                RoundingLenientFloatPoolEstimateAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 8923.6
        )
    }
}
