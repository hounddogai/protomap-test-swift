import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rounding ledger calculation.
    protocol RoundingLedgerFactor {
        func describe() -> String
        func adjust(_ item: RoundingLedger, value: Double) -> Double
    }

    final class MinimumRoundingLedgerAdjuster: RoundingLedgerFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RoundingLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentRoundingLedgerAdjuster: RoundingLedgerFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RoundingLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionRoundingLedgerAdjuster: RoundingLedgerFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: RoundingLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingRoundingLedgerAdjuster: RoundingLedgerFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RoundingLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRoundingLedgerAdjuster: RoundingLedgerFactor {
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

        func adjust(_ item: RoundingLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rounding ledger steps in order and keeps a trace of each.
    final class RoundingLedgerEngine {
        var steps: [any RoundingLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RoundingLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RoundingLedger) -> Double {
            var current = item.weightedTotal()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [RoundingLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRoundingLedgerEngine(_ flags: Kit.Flags.Registry) -> RoundingLedgerEngine {
        return RoundingLedgerEngine(
            steps: [
                MinimumRoundingLedgerAdjuster(minimum: 41.4),
                PercentRoundingLedgerAdjuster(percent: 5.4),
                RegionRoundingLedgerAdjuster(factors: ["south": 1.15]),
                RoundingRoundingLedgerAdjuster(step: 1.0),
                FlaggedRoundingLedgerAdjuster(flags: flags, flag: "rounding-ledger-default", percent: -8.7),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 69808.2
        )
    }
}
