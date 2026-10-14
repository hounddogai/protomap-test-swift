import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the primary denial metric calculation.
    protocol PrimaryDenialMetricModifier {
        func describe() -> String
        func adjust(_ item: PrimaryDenialMetric, value: Double) -> Double
    }

    final class MinimumPrimaryDenialMetricAdjuster: PrimaryDenialMetricModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryDenialMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingPrimaryDenialMetricAdjuster: PrimaryDenialMetricModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryDenialMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapPrimaryDenialMetricAdjuster: PrimaryDenialMetricModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryDenialMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ChannelPrimaryDenialMetricAdjuster: PrimaryDenialMetricModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: PrimaryDenialMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredPrimaryDenialMetricAdjuster: PrimaryDenialMetricModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryDenialMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedPrimaryDenialMetricAdjuster: PrimaryDenialMetricModifier {
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

        func adjust(_ item: PrimaryDenialMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary denial metric steps in order and keeps a trace of each.
    final class PrimaryDenialMetricEngine {
        var steps: [any PrimaryDenialMetricModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryDenialMetricModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryDenialMetric) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryDenialMetricModifier = steps[index]
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

        func evaluateAll(_ items: [PrimaryDenialMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryDenialMetricEngine(_ flags: Kit.Flags.Registry) -> PrimaryDenialMetricEngine {
        return PrimaryDenialMetricEngine(
            steps: [
                MinimumPrimaryDenialMetricAdjuster(minimum: 20.9),
                RoundingPrimaryDenialMetricAdjuster(step: 1.0),
                CapPrimaryDenialMetricAdjuster(cap: 11064.0),
                ChannelPrimaryDenialMetricAdjuster(factors: ["west": 0.79]),
                TieredPrimaryDenialMetricAdjuster(
                    bounds: [279.0, 3605.0, 6748.0, 7507.0],
                    rates: [0.83, 0.93, 0.93, 1.07]
                ),
                FlaggedPrimaryDenialMetricAdjuster(flags: flags, flag: "primary-denial-metric-batched", percent: 5.1),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 32849.0
        )
    }
}
