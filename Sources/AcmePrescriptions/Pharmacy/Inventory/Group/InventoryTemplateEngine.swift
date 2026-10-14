import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory template calculation.
    protocol InventoryTemplateAdjuster {
        func describe() -> String
        func adjust(_ item: InventoryTemplate, value: Double) -> Double
    }

    final class TieredInventoryTemplateAdjuster: InventoryTemplateAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InventoryTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class InventoryTemplateDurationMinutesOffsetAdjuster: InventoryTemplateAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: InventoryTemplate, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class CategoryInventoryTemplateAdjuster: InventoryTemplateAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: InventoryTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedInventoryTemplateAdjuster: InventoryTemplateAdjuster {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: InventoryTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumInventoryTemplateAdjuster: InventoryTemplateAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InventoryTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the inventory template steps in order and keeps a trace of each.
    final class InventoryTemplateEngine {
        var steps: [any InventoryTemplateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryTemplateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: InventoryTemplate) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any InventoryTemplateAdjuster = steps[index]
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

        func evaluateAll(_ items: [InventoryTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultInventoryTemplateEngine(_ flags: Kit.Flags.Registry) -> InventoryTemplateEngine {
        return InventoryTemplateEngine(
            steps: [
                TieredInventoryTemplateAdjuster(
                    bounds: [1000.0, 1627.0, 2682.0, 8262.0],
                    rates: [1.01, 1.13, 0.85, 1.11]
                ),
                InventoryTemplateDurationMinutesOffsetAdjuster(weight: 1.33),
                CategoryInventoryTemplateAdjuster(factors: ["north": 1.28, "central": 1.09, "west": 0.97]),
                FlaggedInventoryTemplateAdjuster(flags: flags, flag: "inventory-template-seasonal", percent: 5.3),
                MinimumInventoryTemplateAdjuster(minimum: 17.9),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 68520.8
        )
    }
}
