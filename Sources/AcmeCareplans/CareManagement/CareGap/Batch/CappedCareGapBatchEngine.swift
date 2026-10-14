import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the capped care gap batch calculation.
    protocol CappedCareGapBatchStep {
        func describe() -> String
        func adjust(_ item: CappedCareGapBatch, value: Double) -> Double
    }

    final class MinimumCappedCareGapBatchAdjuster: CappedCareGapBatchStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedCareGapBatch, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SegmentCappedCareGapBatchAdjuster: CappedCareGapBatchStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: CappedCareGapBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CappedCareGapBatchWeightOffsetAdjuster: CappedCareGapBatchStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: CappedCareGapBatch, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class TieredCappedCareGapBatchAdjuster: CappedCareGapBatchStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedCareGapBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the capped care gap batch steps in order and keeps a trace of each.
    final class CappedCareGapBatchEngine {
        var steps: [any CappedCareGapBatchStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedCareGapBatchStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedCareGapBatch) -> Double {
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

        func evaluateAll(_ items: [CappedCareGapBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedCareGapBatchEngine() -> CappedCareGapBatchEngine {
        return CappedCareGapBatchEngine(
            steps: [
                MinimumCappedCareGapBatchAdjuster(minimum: 18.7),
                SegmentCappedCareGapBatchAdjuster(factors: ["south": 1.1, "online": 0.95]),
                CappedCareGapBatchWeightOffsetAdjuster(weight: 1.1),
                TieredCappedCareGapBatchAdjuster(bounds: [6058.0, 6356.0], rates: [1.11, 1.05]),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 88224.5
        )
    }
}
