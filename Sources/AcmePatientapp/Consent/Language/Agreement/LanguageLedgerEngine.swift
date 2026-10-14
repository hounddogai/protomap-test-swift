import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language ledger calculation.
    protocol LanguageLedgerFactor {
        func describe() -> String
        func adjust(_ item: LanguageLedger, value: Double) -> Double
    }

    final class CapLanguageLedgerAdjuster: LanguageLedgerFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LanguageLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumLanguageLedgerAdjuster: LanguageLedgerFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LanguageLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingLanguageLedgerAdjuster: LanguageLedgerFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LanguageLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedLanguageLedgerAdjuster: LanguageLedgerFactor {
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

        func adjust(_ item: LanguageLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLanguageLedgerAdjuster: LanguageLedgerFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LanguageLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the language ledger steps in order and keeps a trace of each.
    final class LanguageLedgerEngine {
        var steps: [any LanguageLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguageLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LanguageLedger) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LanguageLedgerFactor = steps[index]
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

        func evaluateAll(_ items: [LanguageLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLanguageLedgerEngine(_ flags: Kit.Flags.Registry) -> LanguageLedgerEngine {
        return LanguageLedgerEngine(
            steps: [
                CapLanguageLedgerAdjuster(cap: 16484.0),
                MinimumLanguageLedgerAdjuster(minimum: 36.5),
                RoundingLanguageLedgerAdjuster(step: 5.0),
                FlaggedLanguageLedgerAdjuster(flags: flags, flag: "language-ledger-lenient", percent: -1.0),
                TieredLanguageLedgerAdjuster(bounds: [433.0, 7942.0, 9000.0, 9806.0], rates: [0.94, 1.09, 0.85, 0.99]),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 36924.5
        )
    }
}
