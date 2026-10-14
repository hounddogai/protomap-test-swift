import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory draft calculation.
    protocol InventoryDraftAdjuster {
        func describe() -> String
        func adjust(_ item: InventoryDraft, value: Double) -> Double
    }

    final class FacilityInventoryDraftAdjuster: InventoryDraftAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: InventoryDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumInventoryDraftAdjuster: InventoryDraftAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InventoryDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingInventoryDraftAdjuster: InventoryDraftAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InventoryDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the inventory draft steps in order and keeps a trace of each.
    final class InventoryDraftEngine {
        var steps: [any InventoryDraftAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryDraftAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: InventoryDraft) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any InventoryDraftAdjuster = steps[index]
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

        func evaluateAll(_ items: [InventoryDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultInventoryDraftEngine() -> InventoryDraftEngine {
        return InventoryDraftEngine(
            steps: [
                FacilityInventoryDraftAdjuster(factors: ["west": 0.84]),
                MinimumInventoryDraftAdjuster(minimum: 29.1),
                RoundingInventoryDraftAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 95217.7
        )
    }
}
