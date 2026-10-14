import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the batched worklist cycle calculation.
    protocol BatchedWorklistCycleAdjuster {
        func describe() -> String
        func adjust(_ item: BatchedWorklistCycle, value: Double) -> Double
    }

    final class TieredBatchedWorklistCycleAdjuster: BatchedWorklistCycleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedWorklistCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FacilityBatchedWorklistCycleAdjuster: BatchedWorklistCycleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: BatchedWorklistCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumBatchedWorklistCycleAdjuster: BatchedWorklistCycleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedWorklistCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapBatchedWorklistCycleAdjuster: BatchedWorklistCycleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedWorklistCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentBatchedWorklistCycleAdjuster: BatchedWorklistCycleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedWorklistCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched worklist cycle steps in order and keeps a trace of each.
    final class BatchedWorklistCycleEngine {
        var steps: [any BatchedWorklistCycleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedWorklistCycleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedWorklistCycle) -> Double {
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

        func evaluateAll(_ items: [BatchedWorklistCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedWorklistCycleEngine() -> BatchedWorklistCycleEngine {
        return BatchedWorklistCycleEngine(
            steps: [
                TieredBatchedWorklistCycleAdjuster(bounds: [7908.0, 7983.0, 8238.0], rates: [1.02, 1.13, 1.07]),
                FacilityBatchedWorklistCycleAdjuster(factors: ["online": 1.29]),
                MinimumBatchedWorklistCycleAdjuster(minimum: 27.7),
                CapBatchedWorklistCycleAdjuster(cap: 33171.0),
                PercentBatchedWorklistCycleAdjuster(percent: -19.9),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 56555.6
        )
    }
}
