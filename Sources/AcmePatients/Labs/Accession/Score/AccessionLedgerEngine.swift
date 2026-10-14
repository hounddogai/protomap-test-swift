import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession ledger calculation.
    protocol AccessionLedgerStep {
        func describe() -> String
        func adjust(_ item: AccessionLedger, value: Double) -> Double
    }

    final class RoundingAccessionLedgerAdjuster: AccessionLedgerStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AccessionLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredAccessionLedgerAdjuster: AccessionLedgerStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AccessionLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class AccessionLedgerBudgetOffsetAdjuster: AccessionLedgerStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: AccessionLedger, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class NameAccessionLedgerAdjuster: AccessionLedgerStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: AccessionLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumAccessionLedgerAdjuster: AccessionLedgerStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AccessionLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedAccessionLedgerAdjuster: AccessionLedgerStep {
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

        func adjust(_ item: AccessionLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the accession ledger steps in order and keeps a trace of each.
    final class AccessionLedgerEngine {
        var steps: [any AccessionLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AccessionLedger) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any AccessionLedgerStep = steps[index]
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

        func evaluateAll(_ items: [AccessionLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAccessionLedgerEngine(_ flags: Kit.Flags.Registry) -> AccessionLedgerEngine {
        return AccessionLedgerEngine(
            steps: [
                RoundingAccessionLedgerAdjuster(step: 1.0),
                TieredAccessionLedgerAdjuster(bounds: [8002.0, 9894.0], rates: [1.12, 0.81]),
                AccessionLedgerBudgetOffsetAdjuster(weight: 0.53),
                NameAccessionLedgerAdjuster(factors: ["south": 1.23]),
                MinimumAccessionLedgerAdjuster(minimum: 17.6),
                FlaggedAccessionLedgerAdjuster(flags: flags, flag: "accession-ledger-scheduled", percent: -5.9),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 95332.1
        )
    }
}
