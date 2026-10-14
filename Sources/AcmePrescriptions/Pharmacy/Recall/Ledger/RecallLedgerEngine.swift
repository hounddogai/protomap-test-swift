import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the recall ledger calculation.
    protocol RecallLedgerAdjuster {
        func describe() -> String
        func adjust(_ item: RecallLedger, value: Double) -> Double
    }

    final class TieredRecallLedgerAdjuster: RecallLedgerAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RecallLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRecallLedgerAdjuster: RecallLedgerAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RecallLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumRecallLedgerAdjuster: RecallLedgerAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RecallLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the recall ledger steps in order and keeps a trace of each.
    final class RecallLedgerEngine {
        var steps: [any RecallLedgerAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RecallLedgerAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RecallLedger) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [RecallLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRecallLedgerEngine() -> RecallLedgerEngine {
        return RecallLedgerEngine(
            steps: [
                TieredRecallLedgerAdjuster(bounds: [2608.0, 2650.0, 7157.0, 8172.0], rates: [0.88, 0.86, 1.13, 0.88]),
                RoundingRecallLedgerAdjuster(step: 1.0),
                MinimumRecallLedgerAdjuster(minimum: 45.0),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 35162.7
        )
    }
}
