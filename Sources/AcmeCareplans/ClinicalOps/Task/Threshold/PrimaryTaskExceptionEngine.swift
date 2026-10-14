import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the primary task exception calculation.
    protocol PrimaryTaskExceptionAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryTaskException, value: Double) -> Double
    }

    final class RoundingPrimaryTaskExceptionAdjuster: PrimaryTaskExceptionAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryTaskException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredPrimaryTaskExceptionAdjuster: PrimaryTaskExceptionAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryTaskException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumPrimaryTaskExceptionAdjuster: PrimaryTaskExceptionAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryTaskException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PrimaryTaskExceptionCopayOffsetAdjuster: PrimaryTaskExceptionAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: PrimaryTaskException, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    /// Runs the primary task exception steps in order and keeps a trace of each.
    final class PrimaryTaskExceptionEngine {
        var steps: [any PrimaryTaskExceptionAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryTaskExceptionAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryTaskException) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [PrimaryTaskException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryTaskExceptionEngine() -> PrimaryTaskExceptionEngine {
        return PrimaryTaskExceptionEngine(
            steps: [
                RoundingPrimaryTaskExceptionAdjuster(step: 5.0),
                TieredPrimaryTaskExceptionAdjuster(bounds: [1138.0, 2653.0], rates: [1.18, 1.18]),
                MinimumPrimaryTaskExceptionAdjuster(minimum: 41.8),
                PrimaryTaskExceptionCopayOffsetAdjuster(weight: 0.62),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 23593.3
        )
    }
}
