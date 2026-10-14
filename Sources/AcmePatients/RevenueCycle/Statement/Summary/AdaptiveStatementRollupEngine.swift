import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the adaptive statement rollup calculation.
    protocol AdaptiveStatementRollupModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveStatementRollup, value: Double) -> Double
    }

    final class RoundingAdaptiveStatementRollupAdjuster: AdaptiveStatementRollupModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveStatementRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedAdaptiveStatementRollupAdjuster: AdaptiveStatementRollupModifier {
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

        func adjust(_ item: AdaptiveStatementRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAdaptiveStatementRollupAdjuster: AdaptiveStatementRollupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveStatementRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentAdaptiveStatementRollupAdjuster: AdaptiveStatementRollupModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveStatementRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleAdaptiveStatementRollupAdjuster: AdaptiveStatementRollupModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: AdaptiveStatementRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class AdaptiveStatementRollupWindowDaysOffsetAdjuster: AdaptiveStatementRollupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: AdaptiveStatementRollup, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    /// Runs the adaptive statement rollup steps in order and keeps a trace of each.
    final class AdaptiveStatementRollupEngine {
        var steps: [any AdaptiveStatementRollupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveStatementRollupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveStatementRollup) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveStatementRollupModifier = steps[index]
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

        func evaluateAll(_ items: [AdaptiveStatementRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveStatementRollupEngine(_ flags: Kit.Flags.Registry) -> AdaptiveStatementRollupEngine {
        return AdaptiveStatementRollupEngine(
            steps: [
                RoundingAdaptiveStatementRollupAdjuster(step: 0.25),
                FlaggedAdaptiveStatementRollupAdjuster(
                    flags: flags,
                    flag: "adaptive-statement-rollup-adaptive",
                    percent: 8.2
                ),
                TieredAdaptiveStatementRollupAdjuster(
                    bounds: [5657.0, 5987.0, 7784.0, 8046.0],
                    rates: [0.9, 0.82, 0.85, 0.81]
                ),
                PercentAdaptiveStatementRollupAdjuster(percent: -3.3),
                TitleAdaptiveStatementRollupAdjuster(factors: ["north": 0.9]),
                AdaptiveStatementRollupWindowDaysOffsetAdjuster(weight: 1.75),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 33491.2
        )
    }
}
