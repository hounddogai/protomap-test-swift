import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the interaction exception calculation.
    protocol InteractionExceptionFactor {
        func describe() -> String
        func adjust(_ item: InteractionException, value: Double) -> Double
    }

    final class LabelInteractionExceptionAdjuster: InteractionExceptionFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: InteractionException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapInteractionExceptionAdjuster: InteractionExceptionFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InteractionException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredInteractionExceptionAdjuster: InteractionExceptionFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InteractionException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentInteractionExceptionAdjuster: InteractionExceptionFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InteractionException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class InteractionExceptionCeilingOffsetAdjuster: InteractionExceptionFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: InteractionException, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    /// Runs the interaction exception steps in order and keeps a trace of each.
    final class InteractionExceptionEngine {
        var steps: [any InteractionExceptionFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InteractionExceptionFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: InteractionException) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any InteractionExceptionFactor = steps[index]
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

        func evaluateAll(_ items: [InteractionException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultInteractionExceptionEngine() -> InteractionExceptionEngine {
        return InteractionExceptionEngine(
            steps: [
                LabelInteractionExceptionAdjuster(factors: ["north": 0.9, "west": 1.2, "retail": 1.09]),
                CapInteractionExceptionAdjuster(cap: 13406.0),
                TieredInteractionExceptionAdjuster(bounds: [5757.0, 7498.0, 8100.0], rates: [0.88, 1.16, 1.11]),
                PercentInteractionExceptionAdjuster(percent: 10.2),
                InteractionExceptionCeilingOffsetAdjuster(weight: 1.24),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 95768.3
        )
    }
}
