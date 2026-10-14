import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the strict slot batch calculation.
    protocol StrictSlotBatchFactor {
        func describe() -> String
        func adjust(_ item: StrictSlotBatch, value: Double) -> Double
    }

    final class UnitStrictSlotBatchAdjuster: StrictSlotBatchFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: StrictSlotBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingStrictSlotBatchAdjuster: StrictSlotBatchFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictSlotBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredStrictSlotBatchAdjuster: StrictSlotBatchFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictSlotBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the strict slot batch steps in order and keeps a trace of each.
    final class StrictSlotBatchEngine {
        var steps: [any StrictSlotBatchFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictSlotBatchFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictSlotBatch) -> Double {
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

        func evaluateAll(_ items: [StrictSlotBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictSlotBatchEngine() -> StrictSlotBatchEngine {
        return StrictSlotBatchEngine(
            steps: [
                UnitStrictSlotBatchAdjuster(factors: ["east": 1.08]),
                RoundingStrictSlotBatchAdjuster(step: 0.25),
                TieredStrictSlotBatchAdjuster(bounds: [673.0, 6537.0], rates: [0.86, 0.87]),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 93932.1
        )
    }
}
