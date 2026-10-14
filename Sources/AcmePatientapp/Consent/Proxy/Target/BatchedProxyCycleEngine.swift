import AcmePlatform
import Foundation

extension Consent {
    /// One step of the batched proxy cycle calculation.
    protocol BatchedProxyCycleFactor {
        func describe() -> String
        func adjust(_ item: BatchedProxyCycle, value: Double) -> Double
    }

    final class PercentBatchedProxyCycleAdjuster: BatchedProxyCycleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedProxyCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapBatchedProxyCycleAdjuster: BatchedProxyCycleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedProxyCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumBatchedProxyCycleAdjuster: BatchedProxyCycleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedProxyCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingBatchedProxyCycleAdjuster: BatchedProxyCycleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedProxyCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the batched proxy cycle steps in order and keeps a trace of each.
    final class BatchedProxyCycleEngine {
        var steps: [any BatchedProxyCycleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedProxyCycleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BatchedProxyCycle) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [BatchedProxyCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBatchedProxyCycleEngine() -> BatchedProxyCycleEngine {
        return BatchedProxyCycleEngine(
            steps: [
                PercentBatchedProxyCycleAdjuster(percent: -4.8),
                CapBatchedProxyCycleAdjuster(cap: 33062.0),
                MinimumBatchedProxyCycleAdjuster(minimum: 32.3),
                RoundingBatchedProxyCycleAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 5024.4
        )
    }
}
