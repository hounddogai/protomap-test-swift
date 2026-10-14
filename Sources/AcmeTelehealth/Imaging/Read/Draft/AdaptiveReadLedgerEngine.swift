import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the adaptive read ledger calculation.
    protocol AdaptiveReadLedgerModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveReadLedger, value: Double) -> Double
    }

    final class TieredAdaptiveReadLedgerAdjuster: AdaptiveReadLedgerModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveReadLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapAdaptiveReadLedgerAdjuster: AdaptiveReadLedgerModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveReadLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedAdaptiveReadLedgerAdjuster: AdaptiveReadLedgerModifier {
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

        func adjust(_ item: AdaptiveReadLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive read ledger steps in order and keeps a trace of each.
    final class AdaptiveReadLedgerEngine {
        var steps: [any AdaptiveReadLedgerModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveReadLedgerModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveReadLedger) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [AdaptiveReadLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveReadLedgerEngine(_ flags: Kit.Flags.Registry) -> AdaptiveReadLedgerEngine {
        return AdaptiveReadLedgerEngine(
            steps: [
                TieredAdaptiveReadLedgerAdjuster(
                    bounds: [1218.0, 2529.0, 3795.0, 7475.0],
                    rates: [0.99, 0.9, 0.87, 1.11]
                ),
                CapAdaptiveReadLedgerAdjuster(cap: 2766.0),
                FlaggedAdaptiveReadLedgerAdjuster(flags: flags, flag: "adaptive-read-ledger-batched", percent: 5.1),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 51744.7
        )
    }
}
