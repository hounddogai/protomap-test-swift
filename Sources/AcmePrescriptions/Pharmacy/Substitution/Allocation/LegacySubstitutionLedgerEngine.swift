import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the legacy substitution ledger calculation.
    protocol LegacySubstitutionLedgerFactor {
        func describe() -> String
        func adjust(_ item: LegacySubstitutionLedger, value: Double) -> Double
    }

    final class FlaggedLegacySubstitutionLedgerAdjuster: LegacySubstitutionLedgerFactor {
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

        func adjust(_ item: LegacySubstitutionLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLegacySubstitutionLedgerAdjuster: LegacySubstitutionLedgerFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacySubstitutionLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleLegacySubstitutionLedgerAdjuster: LegacySubstitutionLedgerFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LegacySubstitutionLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingLegacySubstitutionLedgerAdjuster: LegacySubstitutionLedgerFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacySubstitutionLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapLegacySubstitutionLedgerAdjuster: LegacySubstitutionLedgerFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacySubstitutionLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LegacySubstitutionLedgerPriorityOffsetAdjuster: LegacySubstitutionLedgerFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: LegacySubstitutionLedger, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    /// Runs the legacy substitution ledger steps in order and keeps a trace of each.
    final class LegacySubstitutionLedgerEngine {
        var steps: [any LegacySubstitutionLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacySubstitutionLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacySubstitutionLedger) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacySubstitutionLedgerFactor = steps[index]
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

        func evaluateAll(_ items: [LegacySubstitutionLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacySubstitutionLedgerEngine(_ flags: Kit.Flags.Registry) -> LegacySubstitutionLedgerEngine {
        return LegacySubstitutionLedgerEngine(
            steps: [
                FlaggedLegacySubstitutionLedgerAdjuster(
                    flags: flags,
                    flag: "legacy-substitution-ledger-capped",
                    percent: -2.7
                ),
                MinimumLegacySubstitutionLedgerAdjuster(minimum: 9.7),
                TitleLegacySubstitutionLedgerAdjuster(factors: ["retail": 1.26, "west": 0.88]),
                RoundingLegacySubstitutionLedgerAdjuster(step: 0.05),
                CapLegacySubstitutionLedgerAdjuster(cap: 16583.0),
                LegacySubstitutionLedgerPriorityOffsetAdjuster(weight: 0.83),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 78891.9
        )
    }
}
