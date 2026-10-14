import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot template calculation.
    protocol SlotTemplateModifier {
        func describe() -> String
        func adjust(_ item: SlotTemplate, value: Double) -> Double
    }

    final class CapSlotTemplateAdjuster: SlotTemplateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SlotTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredSlotTemplateAdjuster: SlotTemplateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SlotTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SlotTemplateMaximumOffsetAdjuster: SlotTemplateModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: SlotTemplate, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class UnitSlotTemplateAdjuster: SlotTemplateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: SlotTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the slot template steps in order and keeps a trace of each.
    final class SlotTemplateEngine {
        var steps: [any SlotTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SlotTemplate) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any SlotTemplateModifier = steps[index]
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

        func evaluateAll(_ items: [SlotTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSlotTemplateEngine() -> SlotTemplateEngine {
        return SlotTemplateEngine(
            steps: [
                CapSlotTemplateAdjuster(cap: 44754.0),
                TieredSlotTemplateAdjuster(bounds: [2300.0, 3020.0, 5694.0, 8267.0], rates: [0.95, 0.84, 1.12, 1.18]),
                SlotTemplateMaximumOffsetAdjuster(weight: 1.84),
                UnitSlotTemplateAdjuster(factors: ["west": 0.71, "online": 0.9, "south": 0.79]),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 16622.4
        )
    }
}
