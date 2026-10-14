import AcmePlatform
import Foundation

extension Consent {
    /// One step of the seasonal language ledger calculation.
    protocol SeasonalLanguageLedgerFactor {
        func describe() -> String
        func adjust(_ item: SeasonalLanguageLedger, value: Double) -> Double
    }

    final class PercentSeasonalLanguageLedgerAdjuster: SeasonalLanguageLedgerFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalLanguageLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedSeasonalLanguageLedgerAdjuster: SeasonalLanguageLedgerFactor {
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

        func adjust(_ item: SeasonalLanguageLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionSeasonalLanguageLedgerAdjuster: SeasonalLanguageLedgerFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: SeasonalLanguageLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapSeasonalLanguageLedgerAdjuster: SeasonalLanguageLedgerFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalLanguageLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the seasonal language ledger steps in order and keeps a trace of each.
    final class SeasonalLanguageLedgerEngine {
        var steps: [any SeasonalLanguageLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalLanguageLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SeasonalLanguageLedger) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalLanguageLedgerFactor = steps[index]
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

        func evaluateAll(_ items: [SeasonalLanguageLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSeasonalLanguageLedgerEngine(_ flags: Kit.Flags.Registry) -> SeasonalLanguageLedgerEngine {
        return SeasonalLanguageLedgerEngine(
            steps: [
                PercentSeasonalLanguageLedgerAdjuster(percent: 5.2),
                FlaggedSeasonalLanguageLedgerAdjuster(
                    flags: flags,
                    flag: "seasonal-language-ledger-manual",
                    percent: 9.0
                ),
                RegionSeasonalLanguageLedgerAdjuster(factors: ["online": 0.78, "retail": 1.3]),
                CapSeasonalLanguageLedgerAdjuster(cap: 18202.0),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 8379.4
        )
    }
}
