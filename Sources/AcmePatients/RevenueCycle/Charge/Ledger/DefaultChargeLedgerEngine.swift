import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the default charge ledger calculation.
    protocol DefaultChargeLedgerFactor {
        func describe() -> String
        func adjust(_ item: DefaultChargeLedger, value: Double) -> Double
    }

    final class DefaultChargeLedgerMaximumOffsetAdjuster: DefaultChargeLedgerFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: DefaultChargeLedger, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class FlaggedDefaultChargeLedgerAdjuster: DefaultChargeLedgerFactor {
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

        func adjust(_ item: DefaultChargeLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDefaultChargeLedgerAdjuster: DefaultChargeLedgerFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultChargeLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentDefaultChargeLedgerAdjuster: DefaultChargeLedgerFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultChargeLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelDefaultChargeLedgerAdjuster: DefaultChargeLedgerFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: DefaultChargeLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the default charge ledger steps in order and keeps a trace of each.
    final class DefaultChargeLedgerEngine {
        var steps: [any DefaultChargeLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultChargeLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultChargeLedger) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultChargeLedgerFactor = steps[index]
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

        func evaluateAll(_ items: [DefaultChargeLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultChargeLedgerEngine(_ flags: Kit.Flags.Registry) -> DefaultChargeLedgerEngine {
        return DefaultChargeLedgerEngine(
            steps: [
                DefaultChargeLedgerMaximumOffsetAdjuster(weight: 1.54),
                FlaggedDefaultChargeLedgerAdjuster(flags: flags, flag: "default-charge-ledger-global", percent: 4.0),
                MinimumDefaultChargeLedgerAdjuster(minimum: 20.6),
                PercentDefaultChargeLedgerAdjuster(percent: 15.5),
                LabelDefaultChargeLedgerAdjuster(factors: ["online": 0.77]),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 41763.4
        )
    }
}
