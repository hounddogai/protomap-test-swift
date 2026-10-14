import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the capped skill mix slot calculation.
    protocol CappedSkillMixSlotModifier {
        func describe() -> String
        func adjust(_ item: CappedSkillMixSlot, value: Double) -> Double
    }

    final class PercentCappedSkillMixSlotAdjuster: CappedSkillMixSlotModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedSkillMixSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCappedSkillMixSlotAdjuster: CappedSkillMixSlotModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedSkillMixSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredCappedSkillMixSlotAdjuster: CappedSkillMixSlotModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedSkillMixSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class UnitCappedSkillMixSlotAdjuster: CappedSkillMixSlotModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: CappedSkillMixSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumCappedSkillMixSlotAdjuster: CappedSkillMixSlotModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedSkillMixSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the capped skill mix slot steps in order and keeps a trace of each.
    final class CappedSkillMixSlotEngine {
        var steps: [any CappedSkillMixSlotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedSkillMixSlotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedSkillMixSlot) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedSkillMixSlotModifier = steps[index]
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

        func evaluateAll(_ items: [CappedSkillMixSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedSkillMixSlotEngine() -> CappedSkillMixSlotEngine {
        return CappedSkillMixSlotEngine(
            steps: [
                PercentCappedSkillMixSlotAdjuster(percent: 14.5),
                RoundingCappedSkillMixSlotAdjuster(step: 0.1),
                TieredCappedSkillMixSlotAdjuster(bounds: [3391.0, 5025.0], rates: [1.07, 0.84]),
                UnitCappedSkillMixSlotAdjuster(factors: ["north": 0.77, "west": 1.37, "online": 0.85]),
                MinimumCappedSkillMixSlotAdjuster(minimum: 27.6),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 12699.6
        )
    }
}
