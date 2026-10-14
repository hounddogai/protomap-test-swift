import AcmePlatform
import Foundation

extension Consent {
    /// One step of the lenient language ledger calculation.
    protocol LenientLanguageLedgerFactor {
        func describe() -> String
        func adjust(_ item: LenientLanguageLedger, value: Double) -> Double
    }

    final class CapLenientLanguageLedgerAdjuster: LenientLanguageLedgerFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientLanguageLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumLenientLanguageLedgerAdjuster: LenientLanguageLedgerFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientLanguageLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredLenientLanguageLedgerAdjuster: LenientLanguageLedgerFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientLanguageLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the lenient language ledger steps in order and keeps a trace of each.
    final class LenientLanguageLedgerEngine {
        var steps: [any LenientLanguageLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientLanguageLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientLanguageLedger) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [LenientLanguageLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientLanguageLedgerEngine() -> LenientLanguageLedgerEngine {
        return LenientLanguageLedgerEngine(
            steps: [
                CapLenientLanguageLedgerAdjuster(cap: 17986.0),
                MinimumLenientLanguageLedgerAdjuster(minimum: 18.3),
                TieredLenientLanguageLedgerAdjuster(bounds: [2826.0, 4441.0, 5428.0], rates: [0.84, 1.09, 0.89]),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 7083.8
        )
    }
}
