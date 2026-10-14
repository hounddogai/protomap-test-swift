import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the global remittance exception calculation.
    protocol GlobalRemittanceExceptionFactor {
        func describe() -> String
        func adjust(_ item: GlobalRemittanceException, value: Double) -> Double
    }

    final class TieredGlobalRemittanceExceptionAdjuster: GlobalRemittanceExceptionFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalRemittanceException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedGlobalRemittanceExceptionAdjuster: GlobalRemittanceExceptionFactor {
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

        func adjust(_ item: GlobalRemittanceException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumGlobalRemittanceExceptionAdjuster: GlobalRemittanceExceptionFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalRemittanceException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentGlobalRemittanceExceptionAdjuster: GlobalRemittanceExceptionFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalRemittanceException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global remittance exception steps in order and keeps a trace of each.
    final class GlobalRemittanceExceptionEngine {
        var steps: [any GlobalRemittanceExceptionFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalRemittanceExceptionFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalRemittanceException) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalRemittanceExceptionFactor = steps[index]
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

        func evaluateAll(_ items: [GlobalRemittanceException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalRemittanceExceptionEngine(_ flags: Kit.Flags.Registry) -> GlobalRemittanceExceptionEngine {
        return GlobalRemittanceExceptionEngine(
            steps: [
                TieredGlobalRemittanceExceptionAdjuster(bounds: [3596.0, 6471.0, 7841.0], rates: [1.18, 1.12, 1.04]),
                FlaggedGlobalRemittanceExceptionAdjuster(
                    flags: flags,
                    flag: "global-remittance-exception-manual",
                    percent: -9.1
                ),
                MinimumGlobalRemittanceExceptionAdjuster(minimum: 29.5),
                PercentGlobalRemittanceExceptionAdjuster(percent: 10.2),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 55763.5
        )
    }
}
