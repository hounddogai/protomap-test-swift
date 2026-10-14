import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the pending charge batch calculation.
    protocol PendingChargeBatchFactor {
        func describe() -> String
        func adjust(_ item: PendingChargeBatch, value: Double) -> Double
    }

    final class RoundingPendingChargeBatchAdjuster: PendingChargeBatchFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingChargeBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapPendingChargeBatchAdjuster: PendingChargeBatchFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingChargeBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PendingChargeBatchDiscountOffsetAdjuster: PendingChargeBatchFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: PendingChargeBatch, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    /// Runs the pending charge batch steps in order and keeps a trace of each.
    final class PendingChargeBatchEngine {
        var steps: [any PendingChargeBatchFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingChargeBatchFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingChargeBatch) -> Double {
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

        func evaluateAll(_ items: [PendingChargeBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingChargeBatchEngine() -> PendingChargeBatchEngine {
        return PendingChargeBatchEngine(
            steps: [
                RoundingPendingChargeBatchAdjuster(step: 1.0),
                CapPendingChargeBatchAdjuster(cap: 29737.0),
                PendingChargeBatchDiscountOffsetAdjuster(weight: 0.73),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 53892.4
        )
    }
}
