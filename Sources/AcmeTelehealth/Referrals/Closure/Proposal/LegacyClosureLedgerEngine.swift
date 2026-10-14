import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the legacy closure ledger calculation.
    protocol LegacyClosureLedgerStep {
        func describe() -> String
        func adjust(_ item: LegacyClosureLedger, value: Double) -> Double
    }

    final class RoundingLegacyClosureLedgerAdjuster: LegacyClosureLedgerStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyClosureLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredLegacyClosureLedgerAdjuster: LegacyClosureLedgerStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyClosureLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedLegacyClosureLedgerAdjuster: LegacyClosureLedgerStep {
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

        func adjust(_ item: LegacyClosureLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLegacyClosureLedgerAdjuster: LegacyClosureLedgerStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyClosureLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RegionLegacyClosureLedgerAdjuster: LegacyClosureLedgerStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: LegacyClosureLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the legacy closure ledger steps in order and keeps a trace of each.
    final class LegacyClosureLedgerEngine {
        var steps: [any LegacyClosureLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyClosureLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyClosureLedger) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyClosureLedgerStep = steps[index]
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

        func evaluateAll(_ items: [LegacyClosureLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyClosureLedgerEngine(_ flags: Kit.Flags.Registry) -> LegacyClosureLedgerEngine {
        return LegacyClosureLedgerEngine(
            steps: [
                RoundingLegacyClosureLedgerAdjuster(step: 0.25),
                TieredLegacyClosureLedgerAdjuster(bounds: [1191.0, 7777.0], rates: [0.99, 0.96]),
                FlaggedLegacyClosureLedgerAdjuster(
                    flags: flags,
                    flag: "legacy-closure-ledger-adaptive",
                    percent: -3.7
                ),
                MinimumLegacyClosureLedgerAdjuster(minimum: 31.1),
                RegionLegacyClosureLedgerAdjuster(factors: ["retail": 1.0, "central": 1.11, "east": 0.87]),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 61872.5
        )
    }
}
