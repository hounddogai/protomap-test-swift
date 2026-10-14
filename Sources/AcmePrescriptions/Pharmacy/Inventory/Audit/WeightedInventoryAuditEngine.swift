import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the weighted inventory audit calculation.
    protocol WeightedInventoryAuditAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedInventoryAudit, value: Double) -> Double
    }

    final class PercentWeightedInventoryAuditAdjuster: WeightedInventoryAuditAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedInventoryAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredWeightedInventoryAuditAdjuster: WeightedInventoryAuditAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedInventoryAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class WeightedInventoryAuditQuantityOffsetAdjuster: WeightedInventoryAuditAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: WeightedInventoryAudit, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class MinimumWeightedInventoryAuditAdjuster: WeightedInventoryAuditAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedInventoryAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingWeightedInventoryAuditAdjuster: WeightedInventoryAuditAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedInventoryAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the weighted inventory audit steps in order and keeps a trace of each.
    final class WeightedInventoryAuditEngine {
        var steps: [any WeightedInventoryAuditAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedInventoryAuditAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedInventoryAudit) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedInventoryAuditAdjuster = steps[index]
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

        func evaluateAll(_ items: [WeightedInventoryAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedInventoryAuditEngine() -> WeightedInventoryAuditEngine {
        return WeightedInventoryAuditEngine(
            steps: [
                PercentWeightedInventoryAuditAdjuster(percent: -21.2),
                TieredWeightedInventoryAuditAdjuster(
                    bounds: [2823.0, 5197.0, 7108.0, 9419.0],
                    rates: [1.0, 0.81, 1.19, 1.16]
                ),
                WeightedInventoryAuditQuantityOffsetAdjuster(weight: 0.74),
                MinimumWeightedInventoryAuditAdjuster(minimum: 3.5),
                RoundingWeightedInventoryAuditAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 6591.2
        )
    }
}
