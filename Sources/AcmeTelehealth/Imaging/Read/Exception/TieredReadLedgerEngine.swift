import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the tiered read ledger calculation.
    protocol TieredReadLedgerStep {
        func describe() -> String
        func adjust(_ item: TieredReadLedger, value: Double) -> Double
    }

    final class MinimumTieredReadLedgerAdjuster: TieredReadLedgerStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredReadLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapTieredReadLedgerAdjuster: TieredReadLedgerStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredReadLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredReadLedgerCopayOffsetAdjuster: TieredReadLedgerStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: TieredReadLedger, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class FlaggedTieredReadLedgerAdjuster: TieredReadLedgerStep {
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

        func adjust(_ item: TieredReadLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentTieredReadLedgerAdjuster: TieredReadLedgerStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredReadLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the tiered read ledger steps in order and keeps a trace of each.
    final class TieredReadLedgerEngine {
        var steps: [any TieredReadLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredReadLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredReadLedger) -> Double {
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

        func evaluateAll(_ items: [TieredReadLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredReadLedgerEngine(_ flags: Kit.Flags.Registry) -> TieredReadLedgerEngine {
        return TieredReadLedgerEngine(
            steps: [
                MinimumTieredReadLedgerAdjuster(minimum: 21.3),
                CapTieredReadLedgerAdjuster(cap: 1575.0),
                TieredReadLedgerCopayOffsetAdjuster(weight: 0.38),
                FlaggedTieredReadLedgerAdjuster(flags: flags, flag: "tiered-read-ledger-manual", percent: 9.9),
                PercentTieredReadLedgerAdjuster(percent: -24.0),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 54249.7
        )
    }
}
