import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the batched substitution target calculation.
    protocol BatchedSubstitutionTargetAdjuster {
        func describe() -> String
        func adjust(_ item: BatchedSubstitutionTarget, value: Double) -> Double
    }

    final class BatchedSubstitutionTargetVersionOffsetAdjuster: BatchedSubstitutionTargetAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: BatchedSubstitutionTarget, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class TieredBatchedSubstitutionTargetAdjuster: BatchedSubstitutionTargetAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedSubstitutionTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingBatchedSubstitutionTargetAdjuster: BatchedSubstitutionTargetAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedSubstitutionTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ChannelBatchedSubstitutionTargetAdjuster: BatchedSubstitutionTargetAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: BatchedSubstitutionTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentBatchedSubstitutionTargetAdjuster: BatchedSubstitutionTargetAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedSubstitutionTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched substitution target steps in order and keeps a trace of each.
    final class BatchedSubstitutionTargetEngine {
        var steps: [any BatchedSubstitutionTargetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedSubstitutionTargetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BatchedSubstitutionTarget) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [BatchedSubstitutionTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBatchedSubstitutionTargetEngine() -> BatchedSubstitutionTargetEngine {
        return BatchedSubstitutionTargetEngine(
            steps: [
                BatchedSubstitutionTargetVersionOffsetAdjuster(weight: 1.93),
                TieredBatchedSubstitutionTargetAdjuster(bounds: [5012.0, 6495.0, 8010.0], rates: [1.01, 1.11, 1.13]),
                RoundingBatchedSubstitutionTargetAdjuster(step: 0.05),
                ChannelBatchedSubstitutionTargetAdjuster(factors: ["west": 1.21, "online": 0.87, "north": 0.78]),
                PercentBatchedSubstitutionTargetAdjuster(percent: -2.8),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 85863.9
        )
    }
}
