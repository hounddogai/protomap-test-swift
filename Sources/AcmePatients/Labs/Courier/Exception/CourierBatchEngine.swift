import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier batch calculation.
    protocol CourierBatchModifier {
        func describe() -> String
        func adjust(_ item: CourierBatch, value: Double) -> Double
    }

    final class LabelCourierBatchAdjuster: CourierBatchModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CourierBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredCourierBatchAdjuster: CourierBatchModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CourierBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingCourierBatchAdjuster: CourierBatchModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CourierBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CourierBatchCapacityOffsetAdjuster: CourierBatchModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: CourierBatch, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class CapCourierBatchAdjuster: CourierBatchModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CourierBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the courier batch steps in order and keeps a trace of each.
    final class CourierBatchEngine {
        var steps: [any CourierBatchModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierBatchModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CourierBatch) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [CourierBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCourierBatchEngine() -> CourierBatchEngine {
        return CourierBatchEngine(
            steps: [
                LabelCourierBatchAdjuster(factors: ["central": 1.25, "east": 0.95]),
                TieredCourierBatchAdjuster(bounds: [5542.0, 6767.0, 8976.0], rates: [0.95, 1.01, 0.97]),
                RoundingCourierBatchAdjuster(step: 0.05),
                CourierBatchCapacityOffsetAdjuster(weight: 1.14),
                CapCourierBatchAdjuster(cap: 16730.0),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 90407.8
        )
    }
}
