import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the read ledger calculation.
    protocol ReadLedgerStep {
        func describe() -> String
        func adjust(_ item: ReadLedger, value: Double) -> Double
    }

    final class RoundingReadLedgerAdjuster: ReadLedgerStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReadLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapReadLedgerAdjuster: ReadLedgerStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReadLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredReadLedgerAdjuster: ReadLedgerStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReadLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the read ledger steps in order and keeps a trace of each.
    final class ReadLedgerEngine {
        var steps: [any ReadLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReadLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ReadLedger) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ReadLedgerStep = steps[index]
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

        func evaluateAll(_ items: [ReadLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultReadLedgerEngine() -> ReadLedgerEngine {
        return ReadLedgerEngine(
            steps: [
                RoundingReadLedgerAdjuster(step: 0.05),
                CapReadLedgerAdjuster(cap: 27979.0),
                TieredReadLedgerAdjuster(bounds: [2578.0, 4161.0, 9928.0], rates: [0.95, 0.99, 1.11]),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 35385.7
        )
    }
}
