import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance exception calculation.
    protocol RemittanceExceptionAdjuster {
        func describe() -> String
        func adjust(_ item: RemittanceException, value: Double) -> Double
    }

    final class RoundingRemittanceExceptionAdjuster: RemittanceExceptionAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RemittanceException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameRemittanceExceptionAdjuster: RemittanceExceptionAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RemittanceException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedRemittanceExceptionAdjuster: RemittanceExceptionAdjuster {
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

        func adjust(_ item: RemittanceException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRemittanceExceptionAdjuster: RemittanceExceptionAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RemittanceException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapRemittanceExceptionAdjuster: RemittanceExceptionAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RemittanceException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the remittance exception steps in order and keeps a trace of each.
    final class RemittanceExceptionEngine {
        var steps: [any RemittanceExceptionAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceExceptionAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RemittanceException) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RemittanceExceptionAdjuster = steps[index]
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

        func evaluateAll(_ items: [RemittanceException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRemittanceExceptionEngine(_ flags: Kit.Flags.Registry) -> RemittanceExceptionEngine {
        return RemittanceExceptionEngine(
            steps: [
                RoundingRemittanceExceptionAdjuster(step: 0.1),
                NameRemittanceExceptionAdjuster(factors: ["north": 0.93, "south": 1.03]),
                FlaggedRemittanceExceptionAdjuster(
                    flags: flags,
                    flag: "remittance-exception-scheduled",
                    percent: -2.4
                ),
                MinimumRemittanceExceptionAdjuster(minimum: 44.5),
                CapRemittanceExceptionAdjuster(cap: 38688.0),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 54078.8
        )
    }
}
