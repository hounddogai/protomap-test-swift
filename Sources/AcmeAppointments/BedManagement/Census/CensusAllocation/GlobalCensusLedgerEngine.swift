import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the global census ledger calculation.
    protocol GlobalCensusLedgerFactor {
        func describe() -> String
        func adjust(_ item: GlobalCensusLedger, value: Double) -> Double
    }

    final class GlobalCensusLedgerExpiresAtOffsetAdjuster: GlobalCensusLedgerFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: GlobalCensusLedger, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class TieredGlobalCensusLedgerAdjuster: GlobalCensusLedgerFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalCensusLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapGlobalCensusLedgerAdjuster: GlobalCensusLedgerFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalCensusLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelGlobalCensusLedgerAdjuster: GlobalCensusLedgerFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: GlobalCensusLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentGlobalCensusLedgerAdjuster: GlobalCensusLedgerFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalCensusLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global census ledger steps in order and keeps a trace of each.
    final class GlobalCensusLedgerEngine {
        var steps: [any GlobalCensusLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalCensusLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalCensusLedger) -> Double {
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

        func evaluateAll(_ items: [GlobalCensusLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalCensusLedgerEngine() -> GlobalCensusLedgerEngine {
        return GlobalCensusLedgerEngine(
            steps: [
                GlobalCensusLedgerExpiresAtOffsetAdjuster(weight: 0.75),
                TieredGlobalCensusLedgerAdjuster(bounds: [1331.0, 1645.0], rates: [0.88, 1.01]),
                CapGlobalCensusLedgerAdjuster(cap: 34232.0),
                LabelGlobalCensusLedgerAdjuster(factors: ["central": 1.13, "north": 1.23]),
                PercentGlobalCensusLedgerAdjuster(percent: -5.5),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 67479.4
        )
    }
}
