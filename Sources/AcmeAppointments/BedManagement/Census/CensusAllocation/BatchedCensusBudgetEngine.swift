import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the batched census budget calculation.
    protocol BatchedCensusBudgetAdjuster {
        func describe() -> String
        func adjust(_ item: BatchedCensusBudget, value: Double) -> Double
    }

    final class PercentBatchedCensusBudgetAdjuster: BatchedCensusBudgetAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedCensusBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapBatchedCensusBudgetAdjuster: BatchedCensusBudgetAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedCensusBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredBatchedCensusBudgetAdjuster: BatchedCensusBudgetAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedCensusBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingBatchedCensusBudgetAdjuster: BatchedCensusBudgetAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedCensusBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class BatchedCensusBudgetStartsAtOffsetAdjuster: BatchedCensusBudgetAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: BatchedCensusBudget, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class SourceBatchedCensusBudgetAdjuster: BatchedCensusBudgetAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: BatchedCensusBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the batched census budget steps in order and keeps a trace of each.
    final class BatchedCensusBudgetEngine {
        var steps: [any BatchedCensusBudgetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedCensusBudgetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedCensusBudget) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [BatchedCensusBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedCensusBudgetEngine() -> BatchedCensusBudgetEngine {
        return BatchedCensusBudgetEngine(
            steps: [
                PercentBatchedCensusBudgetAdjuster(percent: -18.6),
                CapBatchedCensusBudgetAdjuster(cap: 16943.0),
                TieredBatchedCensusBudgetAdjuster(
                    bounds: [994.0, 2544.0, 3893.0, 6491.0],
                    rates: [0.83, 0.86, 0.92, 1.1]
                ),
                RoundingBatchedCensusBudgetAdjuster(step: 0.1),
                BatchedCensusBudgetStartsAtOffsetAdjuster(weight: 0.86),
                SourceBatchedCensusBudgetAdjuster(factors: ["central": 1.28, "south": 0.96, "west": 1.27]),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 48302.2
        )
    }
}
