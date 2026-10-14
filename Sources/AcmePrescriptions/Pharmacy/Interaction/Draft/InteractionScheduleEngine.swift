import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the interaction schedule calculation.
    protocol InteractionScheduleStep {
        func describe() -> String
        func adjust(_ item: InteractionSchedule, value: Double) -> Double
    }

    final class TieredInteractionScheduleAdjuster: InteractionScheduleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InteractionSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentInteractionScheduleAdjuster: InteractionScheduleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InteractionSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumInteractionScheduleAdjuster: InteractionScheduleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InteractionSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the interaction schedule steps in order and keeps a trace of each.
    final class InteractionScheduleEngine {
        var steps: [any InteractionScheduleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InteractionScheduleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: InteractionSchedule) -> Double {
            var current = item.adjustedValue()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [InteractionSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultInteractionScheduleEngine() -> InteractionScheduleEngine {
        return InteractionScheduleEngine(
            steps: [
                TieredInteractionScheduleAdjuster(bounds: [2426.0, 2817.0, 3330.0], rates: [1.0, 1.19, 1.16]),
                PercentInteractionScheduleAdjuster(percent: -3.2),
                MinimumInteractionScheduleAdjuster(minimum: 6.0),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 77896.6
        )
    }
}
