import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the batched care protocol ledger calculation.
    protocol BatchedCareProtocolLedgerModifier {
        func describe() -> String
        func adjust(_ item: BatchedCareProtocolLedger, value: Double) -> Double
    }

    final class RoundingBatchedCareProtocolLedgerAdjuster: BatchedCareProtocolLedgerModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedCareProtocolLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumBatchedCareProtocolLedgerAdjuster: BatchedCareProtocolLedgerModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedCareProtocolLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentBatchedCareProtocolLedgerAdjuster: BatchedCareProtocolLedgerModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedCareProtocolLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class BatchedCareProtocolLedgerVersionOffsetAdjuster: BatchedCareProtocolLedgerModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: BatchedCareProtocolLedger, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class LabelBatchedCareProtocolLedgerAdjuster: BatchedCareProtocolLedgerModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: BatchedCareProtocolLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredBatchedCareProtocolLedgerAdjuster: BatchedCareProtocolLedgerModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedCareProtocolLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the batched care protocol ledger steps in order and keeps a trace of each.
    final class BatchedCareProtocolLedgerEngine {
        var steps: [any BatchedCareProtocolLedgerModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedCareProtocolLedgerModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedCareProtocolLedger) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedCareProtocolLedgerModifier = steps[index]
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

        func evaluateAll(_ items: [BatchedCareProtocolLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedCareProtocolLedgerEngine() -> BatchedCareProtocolLedgerEngine {
        return BatchedCareProtocolLedgerEngine(
            steps: [
                RoundingBatchedCareProtocolLedgerAdjuster(step: 5.0),
                MinimumBatchedCareProtocolLedgerAdjuster(minimum: 32.9),
                PercentBatchedCareProtocolLedgerAdjuster(percent: 8.7),
                BatchedCareProtocolLedgerVersionOffsetAdjuster(weight: 1.21),
                LabelBatchedCareProtocolLedgerAdjuster(factors: ["east": 1.24, "south": 0.72, "central": 1.14]),
                TieredBatchedCareProtocolLedgerAdjuster(
                    bounds: [1229.0, 2580.0, 3606.0, 8515.0],
                    rates: [1.17, 0.96, 1.17, 0.81]
                ),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 97445.4
        )
    }
}
