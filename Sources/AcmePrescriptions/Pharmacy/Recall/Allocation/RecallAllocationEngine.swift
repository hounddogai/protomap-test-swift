import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the recall allocation calculation.
    protocol RecallAllocationModifier {
        func describe() -> String
        func adjust(_ item: RecallAllocation, value: Double) -> Double
    }

    final class SourceRecallAllocationAdjuster: RecallAllocationModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: RecallAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRecallAllocationAdjuster: RecallAllocationModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RecallAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRecallAllocationAdjuster: RecallAllocationModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RecallAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingRecallAllocationAdjuster: RecallAllocationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RecallAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the recall allocation steps in order and keeps a trace of each.
    final class RecallAllocationEngine {
        var steps: [any RecallAllocationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RecallAllocationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RecallAllocation) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [RecallAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRecallAllocationEngine() -> RecallAllocationEngine {
        return RecallAllocationEngine(
            steps: [
                SourceRecallAllocationAdjuster(factors: ["online": 1.25, "west": 1.2, "central": 0.89]),
                PercentRecallAllocationAdjuster(percent: -0.9),
                MinimumRecallAllocationAdjuster(minimum: 49.6),
                RoundingRecallAllocationAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 36152.6
        )
    }
}
