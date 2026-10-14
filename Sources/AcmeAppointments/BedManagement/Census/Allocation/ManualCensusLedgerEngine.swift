import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the manual census ledger calculation.
    protocol ManualCensusLedgerFactor {
        func describe() -> String
        func adjust(_ item: ManualCensusLedger, value: Double) -> Double
    }

    final class ManualCensusLedgerCapacityOffsetAdjuster: ManualCensusLedgerFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: ManualCensusLedger, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class LocaleManualCensusLedgerAdjuster: ManualCensusLedgerFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: ManualCensusLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredManualCensusLedgerAdjuster: ManualCensusLedgerFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualCensusLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapManualCensusLedgerAdjuster: ManualCensusLedgerFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualCensusLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the manual census ledger steps in order and keeps a trace of each.
    final class ManualCensusLedgerEngine {
        var steps: [any ManualCensusLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualCensusLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualCensusLedger) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualCensusLedgerFactor = steps[index]
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

        func evaluateAll(_ items: [ManualCensusLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualCensusLedgerEngine() -> ManualCensusLedgerEngine {
        return ManualCensusLedgerEngine(
            steps: [
                ManualCensusLedgerCapacityOffsetAdjuster(weight: 0.87),
                LocaleManualCensusLedgerAdjuster(factors: ["west": 1.36, "central": 1.13, "online": 1.14]),
                TieredManualCensusLedgerAdjuster(
                    bounds: [736.0, 2612.0, 3684.0, 9729.0],
                    rates: [1.17, 1.14, 1.15, 0.94]
                ),
                CapManualCensusLedgerAdjuster(cap: 16582.0),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 38903.2
        )
    }
}
