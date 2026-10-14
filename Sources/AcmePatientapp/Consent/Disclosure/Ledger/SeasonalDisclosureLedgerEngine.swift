import AcmePlatform
import Foundation

extension Consent {
    /// One step of the seasonal disclosure ledger calculation.
    protocol SeasonalDisclosureLedgerModifier {
        func describe() -> String
        func adjust(_ item: SeasonalDisclosureLedger, value: Double) -> Double
    }

    final class LabelSeasonalDisclosureLedgerAdjuster: SeasonalDisclosureLedgerModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: SeasonalDisclosureLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedSeasonalDisclosureLedgerAdjuster: SeasonalDisclosureLedgerModifier {
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

        func adjust(_ item: SeasonalDisclosureLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentSeasonalDisclosureLedgerAdjuster: SeasonalDisclosureLedgerModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalDisclosureLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SeasonalDisclosureLedgerCopayOffsetAdjuster: SeasonalDisclosureLedgerModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: SeasonalDisclosureLedger, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class TieredSeasonalDisclosureLedgerAdjuster: SeasonalDisclosureLedgerModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalDisclosureLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingSeasonalDisclosureLedgerAdjuster: SeasonalDisclosureLedgerModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalDisclosureLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the seasonal disclosure ledger steps in order and keeps a trace of each.
    final class SeasonalDisclosureLedgerEngine {
        var steps: [any SeasonalDisclosureLedgerModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalDisclosureLedgerModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalDisclosureLedger) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [SeasonalDisclosureLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalDisclosureLedgerEngine(_ flags: Kit.Flags.Registry) -> SeasonalDisclosureLedgerEngine {
        return SeasonalDisclosureLedgerEngine(
            steps: [
                LabelSeasonalDisclosureLedgerAdjuster(factors: ["central": 1.02]),
                FlaggedSeasonalDisclosureLedgerAdjuster(
                    flags: flags,
                    flag: "seasonal-disclosure-ledger-seasonal",
                    percent: 5.1
                ),
                PercentSeasonalDisclosureLedgerAdjuster(percent: 6.5),
                SeasonalDisclosureLedgerCopayOffsetAdjuster(weight: 1.81),
                TieredSeasonalDisclosureLedgerAdjuster(bounds: [1517.0, 5758.0], rates: [1.01, 1.17]),
                RoundingSeasonalDisclosureLedgerAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 24690.9
        )
    }
}
