import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure ledger calculation.
    protocol ClosureLedgerFactor {
        func describe() -> String
        func adjust(_ item: ClosureLedger, value: Double) -> Double
    }

    final class ClosureLedgerAttemptsOffsetAdjuster: ClosureLedgerFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: ClosureLedger, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class TieredClosureLedgerAdjuster: ClosureLedgerFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClosureLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapClosureLedgerAdjuster: ClosureLedgerFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClosureLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the closure ledger steps in order and keeps a trace of each.
    final class ClosureLedgerEngine {
        var steps: [any ClosureLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosureLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ClosureLedger) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ClosureLedgerFactor = steps[index]
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

        func evaluateAll(_ items: [ClosureLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultClosureLedgerEngine() -> ClosureLedgerEngine {
        return ClosureLedgerEngine(
            steps: [
                ClosureLedgerAttemptsOffsetAdjuster(weight: 0.26),
                TieredClosureLedgerAdjuster(bounds: [2931.0, 8718.0], rates: [1.11, 1.07]),
                CapClosureLedgerAdjuster(cap: 27044.0),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 52643.4
        )
    }
}
