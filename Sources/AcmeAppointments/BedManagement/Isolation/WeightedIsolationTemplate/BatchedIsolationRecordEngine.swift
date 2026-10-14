import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the batched isolation record calculation.
    protocol BatchedIsolationRecordFactor {
        func describe() -> String
        func adjust(_ item: BatchedIsolationRecord, value: Double) -> Double
    }

    final class TieredBatchedIsolationRecordAdjuster: BatchedIsolationRecordFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedIsolationRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentBatchedIsolationRecordAdjuster: BatchedIsolationRecordFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedIsolationRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelBatchedIsolationRecordAdjuster: BatchedIsolationRecordFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: BatchedIsolationRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the batched isolation record steps in order and keeps a trace of each.
    final class BatchedIsolationRecordEngine {
        var steps: [any BatchedIsolationRecordFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedIsolationRecordFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedIsolationRecord) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [BatchedIsolationRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedIsolationRecordEngine() -> BatchedIsolationRecordEngine {
        return BatchedIsolationRecordEngine(
            steps: [
                TieredBatchedIsolationRecordAdjuster(bounds: [3421.0, 8867.0, 9182.0], rates: [1.09, 1.15, 1.19]),
                PercentBatchedIsolationRecordAdjuster(percent: 15.2),
                LabelBatchedIsolationRecordAdjuster(factors: ["central": 0.93]),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 3232.1
        )
    }
}
