import AcmePlatform
import Foundation

extension Labs {
    /// One step of the batched reference range mapping calculation.
    protocol BatchedReferenceRangeMappingAdjuster {
        func describe() -> String
        func adjust(_ item: BatchedReferenceRangeMapping, value: Double) -> Double
    }

    final class MinimumBatchedReferenceRangeMappingAdjuster: BatchedReferenceRangeMappingAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedReferenceRangeMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentBatchedReferenceRangeMappingAdjuster: BatchedReferenceRangeMappingAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedReferenceRangeMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapBatchedReferenceRangeMappingAdjuster: BatchedReferenceRangeMappingAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedReferenceRangeMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredBatchedReferenceRangeMappingAdjuster: BatchedReferenceRangeMappingAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedReferenceRangeMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the batched reference range mapping steps in order and keeps a trace of each.
    final class BatchedReferenceRangeMappingEngine {
        var steps: [any BatchedReferenceRangeMappingAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedReferenceRangeMappingAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedReferenceRangeMapping) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [BatchedReferenceRangeMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedReferenceRangeMappingEngine() -> BatchedReferenceRangeMappingEngine {
        return BatchedReferenceRangeMappingEngine(
            steps: [
                MinimumBatchedReferenceRangeMappingAdjuster(minimum: 5.2),
                PercentBatchedReferenceRangeMappingAdjuster(percent: 10.6),
                CapBatchedReferenceRangeMappingAdjuster(cap: 13244.0),
                TieredBatchedReferenceRangeMappingAdjuster(
                    bounds: [2319.0, 5427.0, 8035.0, 9850.0],
                    rates: [1.11, 1.2, 1.03, 0.93]
                ),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 31749.1
        )
    }
}
