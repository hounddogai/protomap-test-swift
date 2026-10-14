import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the manual authorization rollup calculation.
    protocol ManualAuthorizationRollupStep {
        func describe() -> String
        func adjust(_ item: ManualAuthorizationRollup, value: Double) -> Double
    }

    final class CategoryManualAuthorizationRollupAdjuster: ManualAuthorizationRollupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: ManualAuthorizationRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingManualAuthorizationRollupAdjuster: ManualAuthorizationRollupStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualAuthorizationRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedManualAuthorizationRollupAdjuster: ManualAuthorizationRollupStep {
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

        func adjust(_ item: ManualAuthorizationRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentManualAuthorizationRollupAdjuster: ManualAuthorizationRollupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualAuthorizationRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredManualAuthorizationRollupAdjuster: ManualAuthorizationRollupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualAuthorizationRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the manual authorization rollup steps in order and keeps a trace of each.
    final class ManualAuthorizationRollupEngine {
        var steps: [any ManualAuthorizationRollupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualAuthorizationRollupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualAuthorizationRollup) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualAuthorizationRollupStep = steps[index]
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

        func evaluateAll(_ items: [ManualAuthorizationRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualAuthorizationRollupEngine(_ flags: Kit.Flags.Registry) -> ManualAuthorizationRollupEngine {
        return ManualAuthorizationRollupEngine(
            steps: [
                CategoryManualAuthorizationRollupAdjuster(factors: ["west": 0.77, "north": 1.23, "online": 0.94]),
                RoundingManualAuthorizationRollupAdjuster(step: 1.0),
                FlaggedManualAuthorizationRollupAdjuster(
                    flags: flags,
                    flag: "manual-authorization-rollup-lenient",
                    percent: 9.6
                ),
                PercentManualAuthorizationRollupAdjuster(percent: 22.1),
                TieredManualAuthorizationRollupAdjuster(bounds: [1541.0, 5866.0, 7605.0], rates: [0.97, 0.95, 1.01]),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 49556.1
        )
    }
}
