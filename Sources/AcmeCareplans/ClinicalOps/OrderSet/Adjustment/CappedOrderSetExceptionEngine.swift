import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the capped order set exception calculation.
    protocol CappedOrderSetExceptionAdjuster {
        func describe() -> String
        func adjust(_ item: CappedOrderSetException, value: Double) -> Double
    }

    final class MinimumCappedOrderSetExceptionAdjuster: CappedOrderSetExceptionAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedOrderSetException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ChannelCappedOrderSetExceptionAdjuster: CappedOrderSetExceptionAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: CappedOrderSetException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCappedOrderSetExceptionAdjuster: CappedOrderSetExceptionAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedOrderSetException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CappedOrderSetExceptionRateOffsetAdjuster: CappedOrderSetExceptionAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: CappedOrderSetException, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    /// Runs the capped order set exception steps in order and keeps a trace of each.
    final class CappedOrderSetExceptionEngine {
        var steps: [any CappedOrderSetExceptionAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedOrderSetExceptionAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CappedOrderSetException) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedOrderSetExceptionAdjuster = steps[index]
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

        func evaluateAll(_ items: [CappedOrderSetException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCappedOrderSetExceptionEngine() -> CappedOrderSetExceptionEngine {
        return CappedOrderSetExceptionEngine(
            steps: [
                MinimumCappedOrderSetExceptionAdjuster(minimum: 45.1),
                ChannelCappedOrderSetExceptionAdjuster(factors: ["central": 1.3, "online": 0.75, "retail": 0.98]),
                RoundingCappedOrderSetExceptionAdjuster(step: 0.25),
                CappedOrderSetExceptionRateOffsetAdjuster(weight: 0.17),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 50033.8
        )
    }
}
