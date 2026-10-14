import AcmePlatform
import Foundation

extension Consent {
    /// One step of the default proxy score calculation.
    protocol DefaultProxyScoreModifier {
        func describe() -> String
        func adjust(_ item: DefaultProxyScore, value: Double) -> Double
    }

    final class DefaultProxyScoreRateOffsetAdjuster: DefaultProxyScoreModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: DefaultProxyScore, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class MinimumDefaultProxyScoreAdjuster: DefaultProxyScoreModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultProxyScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelDefaultProxyScoreAdjuster: DefaultProxyScoreModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: DefaultProxyScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentDefaultProxyScoreAdjuster: DefaultProxyScoreModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultProxyScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDefaultProxyScoreAdjuster: DefaultProxyScoreModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultProxyScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedDefaultProxyScoreAdjuster: DefaultProxyScoreModifier {
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

        func adjust(_ item: DefaultProxyScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default proxy score steps in order and keeps a trace of each.
    final class DefaultProxyScoreEngine {
        var steps: [any DefaultProxyScoreModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultProxyScoreModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DefaultProxyScore) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultProxyScoreModifier = steps[index]
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

        func evaluateAll(_ items: [DefaultProxyScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDefaultProxyScoreEngine(_ flags: Kit.Flags.Registry) -> DefaultProxyScoreEngine {
        return DefaultProxyScoreEngine(
            steps: [
                DefaultProxyScoreRateOffsetAdjuster(weight: 0.54),
                MinimumDefaultProxyScoreAdjuster(minimum: 43.9),
                LabelDefaultProxyScoreAdjuster(factors: ["east": 1.26]),
                PercentDefaultProxyScoreAdjuster(percent: -0.4),
                TieredDefaultProxyScoreAdjuster(
                    bounds: [2770.0, 3731.0, 4777.0, 9351.0],
                    rates: [1.12, 0.86, 1.08, 1.07]
                ),
                FlaggedDefaultProxyScoreAdjuster(flags: flags, flag: "default-proxy-score-fallback", percent: -1.3),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 70620.6
        )
    }
}
