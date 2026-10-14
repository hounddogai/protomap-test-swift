import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial baseline calculation.
    protocol DenialBaselineAdjuster {
        func describe() -> String
        func adjust(_ item: DenialBaseline, value: Double) -> Double
    }

    final class LabelDenialBaselineAdjuster: DenialBaselineAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: DenialBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedDenialBaselineAdjuster: DenialBaselineAdjuster {
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

        func adjust(_ item: DenialBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentDenialBaselineAdjuster: DenialBaselineAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DenialBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDenialBaselineAdjuster: DenialBaselineAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DenialBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredDenialBaselineAdjuster: DenialBaselineAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DenialBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapDenialBaselineAdjuster: DenialBaselineAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DenialBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the denial baseline steps in order and keeps a trace of each.
    final class DenialBaselineEngine {
        var steps: [any DenialBaselineAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialBaselineAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DenialBaseline) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any DenialBaselineAdjuster = steps[index]
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

        func evaluateAll(_ items: [DenialBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDenialBaselineEngine(_ flags: Kit.Flags.Registry) -> DenialBaselineEngine {
        return DenialBaselineEngine(
            steps: [
                LabelDenialBaselineAdjuster(factors: ["central": 1.06]),
                FlaggedDenialBaselineAdjuster(flags: flags, flag: "denial-baseline-seasonal", percent: -1.2),
                PercentDenialBaselineAdjuster(percent: -15.6),
                MinimumDenialBaselineAdjuster(minimum: 2.8),
                TieredDenialBaselineAdjuster(bounds: [1382.0, 2973.0, 7848.0, 8043.0], rates: [0.81, 1.1, 1.06, 0.81]),
                CapDenialBaselineAdjuster(cap: 9573.0),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 65248.3
        )
    }
}
