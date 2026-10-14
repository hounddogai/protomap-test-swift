import AcmePlatform
import Foundation

extension Labs {
    /// One step of the seasonal specimen ledger calculation.
    protocol SeasonalSpecimenLedgerStep {
        func describe() -> String
        func adjust(_ item: SeasonalSpecimenLedger, value: Double) -> Double
    }

    final class MinimumSeasonalSpecimenLedgerAdjuster: SeasonalSpecimenLedgerStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalSpecimenLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedSeasonalSpecimenLedgerAdjuster: SeasonalSpecimenLedgerStep {
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

        func adjust(_ item: SeasonalSpecimenLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSeasonalSpecimenLedgerAdjuster: SeasonalSpecimenLedgerStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalSpecimenLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the seasonal specimen ledger steps in order and keeps a trace of each.
    final class SeasonalSpecimenLedgerEngine {
        var steps: [any SeasonalSpecimenLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalSpecimenLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalSpecimenLedger) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [SeasonalSpecimenLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalSpecimenLedgerEngine(_ flags: Kit.Flags.Registry) -> SeasonalSpecimenLedgerEngine {
        return SeasonalSpecimenLedgerEngine(
            steps: [
                MinimumSeasonalSpecimenLedgerAdjuster(minimum: 7.1),
                FlaggedSeasonalSpecimenLedgerAdjuster(
                    flags: flags,
                    flag: "seasonal-specimen-ledger-default",
                    percent: 8.7
                ),
                CapSeasonalSpecimenLedgerAdjuster(cap: 866.0),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 72459.2
        )
    }
}
