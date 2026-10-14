import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory claim calculation.
    protocol InventoryClaimFactor {
        func describe() -> String
        func adjust(_ item: InventoryClaim, value: Double) -> Double
    }

    final class MinimumInventoryClaimAdjuster: InventoryClaimFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InventoryClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingInventoryClaimAdjuster: InventoryClaimFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InventoryClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapInventoryClaimAdjuster: InventoryClaimFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InventoryClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentInventoryClaimAdjuster: InventoryClaimFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InventoryClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WardInventoryClaimAdjuster: InventoryClaimFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: InventoryClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the inventory claim steps in order and keeps a trace of each.
    final class InventoryClaimEngine {
        var steps: [any InventoryClaimFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryClaimFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: InventoryClaim) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any InventoryClaimFactor = steps[index]
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

        func evaluateAll(_ items: [InventoryClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultInventoryClaimEngine() -> InventoryClaimEngine {
        return InventoryClaimEngine(
            steps: [
                MinimumInventoryClaimAdjuster(minimum: 29.4),
                RoundingInventoryClaimAdjuster(step: 0.5),
                CapInventoryClaimAdjuster(cap: 10894.0),
                PercentInventoryClaimAdjuster(percent: -10.4),
                WardInventoryClaimAdjuster(factors: ["retail": 0.98, "west": 0.7]),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 99978.1
        )
    }
}
