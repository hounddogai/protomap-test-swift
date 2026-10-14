import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot forecast calculation.
    protocol SlotForecastAdjuster {
        func describe() -> String
        func adjust(_ item: SlotForecast, value: Double) -> Double
    }

    final class NameSlotForecastAdjuster: SlotForecastAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: SlotForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class SlotForecastRatioOffsetAdjuster: SlotForecastAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: SlotForecast, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class RoundingSlotForecastAdjuster: SlotForecastAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SlotForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the slot forecast steps in order and keeps a trace of each.
    final class SlotForecastEngine {
        var steps: [any SlotForecastAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotForecastAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SlotForecast) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SlotForecastAdjuster = steps[index]
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

        func evaluateAll(_ items: [SlotForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSlotForecastEngine() -> SlotForecastEngine {
        return SlotForecastEngine(
            steps: [
                NameSlotForecastAdjuster(factors: ["west": 0.71]),
                SlotForecastRatioOffsetAdjuster(weight: 0.45),
                RoundingSlotForecastAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 22081.3
        )
    }
}
