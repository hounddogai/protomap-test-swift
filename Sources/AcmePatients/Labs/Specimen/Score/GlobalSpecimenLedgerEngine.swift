import AcmePlatform
import Foundation

extension Labs {
    /// One step of the global specimen ledger calculation.
    protocol GlobalSpecimenLedgerAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalSpecimenLedger, value: Double) -> Double
    }

    final class CapGlobalSpecimenLedgerAdjuster: GlobalSpecimenLedgerAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalSpecimenLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentGlobalSpecimenLedgerAdjuster: GlobalSpecimenLedgerAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalSpecimenLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredGlobalSpecimenLedgerAdjuster: GlobalSpecimenLedgerAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalSpecimenLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingGlobalSpecimenLedgerAdjuster: GlobalSpecimenLedgerAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalSpecimenLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleGlobalSpecimenLedgerAdjuster: GlobalSpecimenLedgerAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: GlobalSpecimenLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedGlobalSpecimenLedgerAdjuster: GlobalSpecimenLedgerAdjuster {
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

        func adjust(_ item: GlobalSpecimenLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global specimen ledger steps in order and keeps a trace of each.
    final class GlobalSpecimenLedgerEngine {
        var steps: [any GlobalSpecimenLedgerAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalSpecimenLedgerAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalSpecimenLedger) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalSpecimenLedgerAdjuster = steps[index]
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

        func evaluateAll(_ items: [GlobalSpecimenLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalSpecimenLedgerEngine(_ flags: Kit.Flags.Registry) -> GlobalSpecimenLedgerEngine {
        return GlobalSpecimenLedgerEngine(
            steps: [
                CapGlobalSpecimenLedgerAdjuster(cap: 42196.0),
                PercentGlobalSpecimenLedgerAdjuster(percent: 14.3),
                TieredGlobalSpecimenLedgerAdjuster(
                    bounds: [1913.0, 3783.0, 4120.0, 8970.0],
                    rates: [1.13, 1.17, 0.85, 1.16]
                ),
                RoundingGlobalSpecimenLedgerAdjuster(step: 5.0),
                TitleGlobalSpecimenLedgerAdjuster(factors: ["central": 1.31, "north": 1.36, "online": 0.99]),
                FlaggedGlobalSpecimenLedgerAdjuster(
                    flags: flags,
                    flag: "global-specimen-ledger-global",
                    percent: -0.2
                ),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 67278.7
        )
    }
}
