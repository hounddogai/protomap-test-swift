import AcmePlatform
import Foundation

extension Labs {
    /// One step of the fallback result ledger calculation.
    protocol FallbackResultLedgerStep {
        func describe() -> String
        func adjust(_ item: FallbackResultLedger, value: Double) -> Double
    }

    final class FlaggedFallbackResultLedgerAdjuster: FallbackResultLedgerStep {
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

        func adjust(_ item: FallbackResultLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredFallbackResultLedgerAdjuster: FallbackResultLedgerStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackResultLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameFallbackResultLedgerAdjuster: FallbackResultLedgerStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: FallbackResultLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the fallback result ledger steps in order and keeps a trace of each.
    final class FallbackResultLedgerEngine {
        var steps: [any FallbackResultLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackResultLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackResultLedger) -> Double {
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

        func evaluateAll(_ items: [FallbackResultLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackResultLedgerEngine(_ flags: Kit.Flags.Registry) -> FallbackResultLedgerEngine {
        return FallbackResultLedgerEngine(
            steps: [
                FlaggedFallbackResultLedgerAdjuster(flags: flags, flag: "fallback-result-ledger-strict", percent: 3.3),
                TieredFallbackResultLedgerAdjuster(bounds: [346.0, 2161.0], rates: [1.04, 1.12]),
                NameFallbackResultLedgerAdjuster(factors: ["east": 1.12, "west": 1.01, "retail": 0.98]),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 75391.3
        )
    }
}
