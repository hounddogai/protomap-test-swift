import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the legacy handoff ledger calculation.
    protocol LegacyHandoffLedgerFactor {
        func describe() -> String
        func adjust(_ item: LegacyHandoffLedger, value: Double) -> Double
    }

    final class CapLegacyHandoffLedgerAdjuster: LegacyHandoffLedgerFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyHandoffLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumLegacyHandoffLedgerAdjuster: LegacyHandoffLedgerFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyHandoffLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelLegacyHandoffLedgerAdjuster: LegacyHandoffLedgerFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LegacyHandoffLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingLegacyHandoffLedgerAdjuster: LegacyHandoffLedgerFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyHandoffLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedLegacyHandoffLedgerAdjuster: LegacyHandoffLedgerFactor {
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

        func adjust(_ item: LegacyHandoffLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the legacy handoff ledger steps in order and keeps a trace of each.
    final class LegacyHandoffLedgerEngine {
        var steps: [any LegacyHandoffLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyHandoffLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LegacyHandoffLedger) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyHandoffLedgerFactor = steps[index]
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

        func evaluateAll(_ items: [LegacyHandoffLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLegacyHandoffLedgerEngine(_ flags: Kit.Flags.Registry) -> LegacyHandoffLedgerEngine {
        return LegacyHandoffLedgerEngine(
            steps: [
                CapLegacyHandoffLedgerAdjuster(cap: 29937.0),
                MinimumLegacyHandoffLedgerAdjuster(minimum: 4.1),
                LabelLegacyHandoffLedgerAdjuster(factors: ["retail": 1.13, "east": 0.88, "west": 1.2]),
                RoundingLegacyHandoffLedgerAdjuster(step: 0.25),
                FlaggedLegacyHandoffLedgerAdjuster(flags: flags, flag: "legacy-handoff-ledger-strict", percent: -9.7),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 21381.8
        )
    }
}
