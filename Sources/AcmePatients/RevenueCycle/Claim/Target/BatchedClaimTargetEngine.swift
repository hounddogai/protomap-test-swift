import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the batched claim target calculation.
    protocol BatchedClaimTargetModifier {
        func describe() -> String
        func adjust(_ item: BatchedClaimTarget, value: Double) -> Double
    }

    final class TieredBatchedClaimTargetAdjuster: BatchedClaimTargetModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedClaimTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentBatchedClaimTargetAdjuster: BatchedClaimTargetModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedClaimTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapBatchedClaimTargetAdjuster: BatchedClaimTargetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedClaimTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class BatchedClaimTargetRatioOffsetAdjuster: BatchedClaimTargetModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: BatchedClaimTarget, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    /// Runs the batched claim target steps in order and keeps a trace of each.
    final class BatchedClaimTargetEngine {
        var steps: [any BatchedClaimTargetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedClaimTargetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BatchedClaimTarget) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [BatchedClaimTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBatchedClaimTargetEngine() -> BatchedClaimTargetEngine {
        return BatchedClaimTargetEngine(
            steps: [
                TieredBatchedClaimTargetAdjuster(
                    bounds: [1527.0, 1997.0, 2220.0, 3119.0],
                    rates: [0.95, 0.8, 1.02, 1.05]
                ),
                PercentBatchedClaimTargetAdjuster(percent: 6.1),
                CapBatchedClaimTargetAdjuster(cap: 37009.0),
                BatchedClaimTargetRatioOffsetAdjuster(weight: 0.73),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 5671.9
        )
    }
}
