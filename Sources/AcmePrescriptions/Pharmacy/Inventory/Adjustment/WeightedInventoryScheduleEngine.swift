import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the weighted inventory schedule calculation.
    protocol WeightedInventoryScheduleAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedInventorySchedule, value: Double) -> Double
    }

    final class WeightedInventoryScheduleCreatedAtOffsetAdjuster: WeightedInventoryScheduleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: WeightedInventorySchedule, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class RoundingWeightedInventoryScheduleAdjuster: WeightedInventoryScheduleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedInventorySchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SourceWeightedInventoryScheduleAdjuster: WeightedInventoryScheduleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: WeightedInventorySchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the weighted inventory schedule steps in order and keeps a trace of each.
    final class WeightedInventoryScheduleEngine {
        var steps: [any WeightedInventoryScheduleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedInventoryScheduleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WeightedInventorySchedule) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [WeightedInventorySchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWeightedInventoryScheduleEngine() -> WeightedInventoryScheduleEngine {
        return WeightedInventoryScheduleEngine(
            steps: [
                WeightedInventoryScheduleCreatedAtOffsetAdjuster(weight: 1.86),
                RoundingWeightedInventoryScheduleAdjuster(step: 0.1),
                SourceWeightedInventoryScheduleAdjuster(factors: ["retail": 0.98, "south": 1.08, "east": 1.28]),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 37338.6
        )
    }
}
