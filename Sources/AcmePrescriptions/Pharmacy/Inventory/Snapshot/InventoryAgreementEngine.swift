import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory agreement calculation.
    protocol InventoryAgreementStep {
        func describe() -> String
        func adjust(_ item: InventoryAgreement, value: Double) -> Double
    }

    final class TieredInventoryAgreementAdjuster: InventoryAgreementStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InventoryAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentInventoryAgreementAdjuster: InventoryAgreementStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InventoryAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingInventoryAgreementAdjuster: InventoryAgreementStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InventoryAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapInventoryAgreementAdjuster: InventoryAgreementStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InventoryAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the inventory agreement steps in order and keeps a trace of each.
    final class InventoryAgreementEngine {
        var steps: [any InventoryAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: InventoryAgreement) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any InventoryAgreementStep = steps[index]
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

        func evaluateAll(_ items: [InventoryAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultInventoryAgreementEngine() -> InventoryAgreementEngine {
        return InventoryAgreementEngine(
            steps: [
                TieredInventoryAgreementAdjuster(bounds: [715.0, 9075.0], rates: [1.02, 0.96]),
                PercentInventoryAgreementAdjuster(percent: -18.0),
                RoundingInventoryAgreementAdjuster(step: 0.5),
                CapInventoryAgreementAdjuster(cap: 29219.0),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 32056.1
        )
    }
}
