import AcmePlatform
import Foundation

extension Consent {
    /// One step of the rolling disclosure budget calculation.
    protocol RollingDisclosureBudgetFactor {
        func describe() -> String
        func adjust(_ item: RollingDisclosureBudget, value: Double) -> Double
    }

    final class TieredRollingDisclosureBudgetAdjuster: RollingDisclosureBudgetFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingDisclosureBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapRollingDisclosureBudgetAdjuster: RollingDisclosureBudgetFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingDisclosureBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelRollingDisclosureBudgetAdjuster: RollingDisclosureBudgetFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: RollingDisclosureBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedRollingDisclosureBudgetAdjuster: RollingDisclosureBudgetFactor {
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

        func adjust(_ item: RollingDisclosureBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rolling disclosure budget steps in order and keeps a trace of each.
    final class RollingDisclosureBudgetEngine {
        var steps: [any RollingDisclosureBudgetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingDisclosureBudgetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingDisclosureBudget) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingDisclosureBudgetFactor = steps[index]
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

        func evaluateAll(_ items: [RollingDisclosureBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingDisclosureBudgetEngine(_ flags: Kit.Flags.Registry) -> RollingDisclosureBudgetEngine {
        return RollingDisclosureBudgetEngine(
            steps: [
                TieredRollingDisclosureBudgetAdjuster(
                    bounds: [232.0, 875.0, 1991.0, 6261.0],
                    rates: [0.86, 0.9, 0.91, 1.19]
                ),
                CapRollingDisclosureBudgetAdjuster(cap: 31134.0),
                LabelRollingDisclosureBudgetAdjuster(factors: ["south": 1.01]),
                FlaggedRollingDisclosureBudgetAdjuster(
                    flags: flags,
                    flag: "rolling-disclosure-budget-tiered",
                    percent: -5.9
                ),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 85039.6
        )
    }
}
