import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the interaction slot calculation.
    protocol InteractionSlotFactor {
        func describe() -> String
        func adjust(_ item: InteractionSlot, value: Double) -> Double
    }

    final class UnitInteractionSlotAdjuster: InteractionSlotFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: InteractionSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class InteractionSlotBatchSizeOffsetAdjuster: InteractionSlotFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: InteractionSlot, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class CapInteractionSlotAdjuster: InteractionSlotFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InteractionSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the interaction slot steps in order and keeps a trace of each.
    final class InteractionSlotEngine {
        var steps: [any InteractionSlotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InteractionSlotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: InteractionSlot) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any InteractionSlotFactor = steps[index]
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

        func evaluateAll(_ items: [InteractionSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultInteractionSlotEngine() -> InteractionSlotEngine {
        return InteractionSlotEngine(
            steps: [
                UnitInteractionSlotAdjuster(factors: ["online": 1.05, "east": 1.31]),
                InteractionSlotBatchSizeOffsetAdjuster(weight: 1.21),
                CapInteractionSlotAdjuster(cap: 46222.0),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 18255.5
        )
    }
}
