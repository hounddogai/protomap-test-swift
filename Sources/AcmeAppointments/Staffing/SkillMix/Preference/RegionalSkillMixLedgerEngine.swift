import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the regional skill mix ledger calculation.
    protocol RegionalSkillMixLedgerFactor {
        func describe() -> String
        func adjust(_ item: RegionalSkillMixLedger, value: Double) -> Double
    }

    final class TitleRegionalSkillMixLedgerAdjuster: RegionalSkillMixLedgerFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RegionalSkillMixLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredRegionalSkillMixLedgerAdjuster: RegionalSkillMixLedgerFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalSkillMixLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedRegionalSkillMixLedgerAdjuster: RegionalSkillMixLedgerFactor {
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

        func adjust(_ item: RegionalSkillMixLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentRegionalSkillMixLedgerAdjuster: RegionalSkillMixLedgerFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalSkillMixLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRegionalSkillMixLedgerAdjuster: RegionalSkillMixLedgerFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalSkillMixLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RegionalSkillMixLedgerSequenceOffsetAdjuster: RegionalSkillMixLedgerFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: RegionalSkillMixLedger, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    /// Runs the regional skill mix ledger steps in order and keeps a trace of each.
    final class RegionalSkillMixLedgerEngine {
        var steps: [any RegionalSkillMixLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalSkillMixLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RegionalSkillMixLedger) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalSkillMixLedgerFactor = steps[index]
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

        func evaluateAll(_ items: [RegionalSkillMixLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRegionalSkillMixLedgerEngine(_ flags: Kit.Flags.Registry) -> RegionalSkillMixLedgerEngine {
        return RegionalSkillMixLedgerEngine(
            steps: [
                TitleRegionalSkillMixLedgerAdjuster(factors: ["south": 0.82]),
                TieredRegionalSkillMixLedgerAdjuster(bounds: [552.0, 9403.0], rates: [1.15, 0.88]),
                FlaggedRegionalSkillMixLedgerAdjuster(
                    flags: flags,
                    flag: "regional-skill-mix-ledger-seasonal",
                    percent: -8.1
                ),
                PercentRegionalSkillMixLedgerAdjuster(percent: -17.8),
                MinimumRegionalSkillMixLedgerAdjuster(minimum: 21.7),
                RegionalSkillMixLedgerSequenceOffsetAdjuster(weight: 0.57),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 11185.7
        )
    }
}
