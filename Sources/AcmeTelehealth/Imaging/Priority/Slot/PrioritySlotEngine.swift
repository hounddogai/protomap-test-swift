import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority slot calculation.
    protocol PrioritySlotStep {
        func describe() -> String
        func adjust(_ item: PrioritySlot, value: Double) -> Double
    }

    final class RegionPrioritySlotAdjuster: PrioritySlotStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: PrioritySlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumPrioritySlotAdjuster: PrioritySlotStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrioritySlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentPrioritySlotAdjuster: PrioritySlotStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrioritySlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPrioritySlotAdjuster: PrioritySlotStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrioritySlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingPrioritySlotAdjuster: PrioritySlotStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrioritySlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the priority slot steps in order and keeps a trace of each.
    final class PrioritySlotEngine {
        var steps: [any PrioritySlotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrioritySlotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrioritySlot) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PrioritySlotStep = steps[index]
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

        func evaluateAll(_ items: [PrioritySlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrioritySlotEngine() -> PrioritySlotEngine {
        return PrioritySlotEngine(
            steps: [
                RegionPrioritySlotAdjuster(factors: ["east": 0.9]),
                MinimumPrioritySlotAdjuster(minimum: 6.6),
                PercentPrioritySlotAdjuster(percent: 24.8),
                TieredPrioritySlotAdjuster(bounds: [2522.0, 2535.0, 4421.0, 7890.0], rates: [0.94, 0.92, 0.85, 0.88]),
                RoundingPrioritySlotAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 49349.9
        )
    }
}
