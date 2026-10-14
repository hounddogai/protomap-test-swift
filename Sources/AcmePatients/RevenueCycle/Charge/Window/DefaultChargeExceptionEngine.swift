import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the default charge exception calculation.
    protocol DefaultChargeExceptionFactor {
        func describe() -> String
        func adjust(_ item: DefaultChargeException, value: Double) -> Double
    }

    final class FlaggedDefaultChargeExceptionAdjuster: DefaultChargeExceptionFactor {
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

        func adjust(_ item: DefaultChargeException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDefaultChargeExceptionAdjuster: DefaultChargeExceptionFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultChargeException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameDefaultChargeExceptionAdjuster: DefaultChargeExceptionFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: DefaultChargeException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapDefaultChargeExceptionAdjuster: DefaultChargeExceptionFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultChargeException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentDefaultChargeExceptionAdjuster: DefaultChargeExceptionFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultChargeException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default charge exception steps in order and keeps a trace of each.
    final class DefaultChargeExceptionEngineExtra {
        var steps: [any DefaultChargeExceptionFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultChargeExceptionFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultChargeException) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultChargeExceptionFactor = steps[index]
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

        func evaluateAll(_ items: [DefaultChargeException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultChargeExceptionEngine(_ flags: Kit.Flags.Registry) -> DefaultChargeExceptionEngineExtra {
        return DefaultChargeExceptionEngineExtra(
            steps: [
                FlaggedDefaultChargeExceptionAdjuster(
                    flags: flags,
                    flag: "default-charge-exception-strict",
                    percent: -1.0
                ),
                RoundingDefaultChargeExceptionAdjuster(step: 1.0),
                NameDefaultChargeExceptionAdjuster(factors: ["retail": 1.27]),
                CapDefaultChargeExceptionAdjuster(cap: 16918.0),
                PercentDefaultChargeExceptionAdjuster(percent: -15.2),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 11992.0
        )
    }
}
