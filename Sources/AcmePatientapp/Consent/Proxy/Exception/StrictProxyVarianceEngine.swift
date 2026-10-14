import AcmePlatform
import Foundation

extension Consent {
    /// One step of the strict proxy variance calculation.
    protocol StrictProxyVarianceStep {
        func describe() -> String
        func adjust(_ item: StrictProxyVariance, value: Double) -> Double
    }

    final class FlaggedStrictProxyVarianceAdjuster: StrictProxyVarianceStep {
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

        func adjust(_ item: StrictProxyVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredStrictProxyVarianceAdjuster: StrictProxyVarianceStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictProxyVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentStrictProxyVarianceAdjuster: StrictProxyVarianceStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictProxyVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict proxy variance steps in order and keeps a trace of each.
    final class StrictProxyVarianceEngine {
        var steps: [any StrictProxyVarianceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictProxyVarianceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictProxyVariance) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictProxyVarianceStep = steps[index]
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

        func evaluateAll(_ items: [StrictProxyVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictProxyVarianceEngine(_ flags: Kit.Flags.Registry) -> StrictProxyVarianceEngine {
        return StrictProxyVarianceEngine(
            steps: [
                FlaggedStrictProxyVarianceAdjuster(flags: flags, flag: "strict-proxy-variance-default", percent: 7.9),
                TieredStrictProxyVarianceAdjuster(bounds: [4410.0, 7739.0], rates: [0.83, 1.05]),
                PercentStrictProxyVarianceAdjuster(percent: 9.2),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 42463.7
        )
    }
}
