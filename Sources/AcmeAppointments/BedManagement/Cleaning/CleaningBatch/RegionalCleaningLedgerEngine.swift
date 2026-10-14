import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the regional cleaning ledger calculation.
    protocol RegionalCleaningLedgerFactor {
        func describe() -> String
        func adjust(_ item: RegionalCleaningLedger, value: Double) -> Double
    }

    final class RoundingRegionalCleaningLedgerAdjuster: RegionalCleaningLedgerFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalCleaningLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumRegionalCleaningLedgerAdjuster: RegionalCleaningLedgerFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalCleaningLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentRegionalCleaningLedgerAdjuster: RegionalCleaningLedgerFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalCleaningLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRegionalCleaningLedgerAdjuster: RegionalCleaningLedgerFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalCleaningLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRegionalCleaningLedgerAdjuster: RegionalCleaningLedgerFactor {
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

        func adjust(_ item: RegionalCleaningLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRegionalCleaningLedgerAdjuster: RegionalCleaningLedgerFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalCleaningLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the regional cleaning ledger steps in order and keeps a trace of each.
    final class RegionalCleaningLedgerEngine {
        var steps: [any RegionalCleaningLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalCleaningLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalCleaningLedger) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [RegionalCleaningLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalCleaningLedgerEngine(_ flags: Kit.Flags.Registry) -> RegionalCleaningLedgerEngine {
        return RegionalCleaningLedgerEngine(
            steps: [
                RoundingRegionalCleaningLedgerAdjuster(step: 0.25),
                MinimumRegionalCleaningLedgerAdjuster(minimum: 2.4),
                PercentRegionalCleaningLedgerAdjuster(percent: 22.6),
                CapRegionalCleaningLedgerAdjuster(cap: 42232.0),
                FlaggedRegionalCleaningLedgerAdjuster(
                    flags: flags,
                    flag: "regional-cleaning-ledger-scheduled",
                    percent: -9.7
                ),
                TieredRegionalCleaningLedgerAdjuster(
                    bounds: [2205.0, 5302.0, 5657.0, 6915.0],
                    rates: [0.94, 0.82, 0.98, 0.91]
                ),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 53953.4
        )
    }
}
