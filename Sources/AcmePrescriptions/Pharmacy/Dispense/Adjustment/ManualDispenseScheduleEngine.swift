import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the manual dispense schedule calculation.
    protocol ManualDispenseScheduleStep {
        func describe() -> String
        func adjust(_ item: ManualDispenseSchedule, value: Double) -> Double
    }

    final class RoundingManualDispenseScheduleAdjuster: ManualDispenseScheduleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualDispenseSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredManualDispenseScheduleAdjuster: ManualDispenseScheduleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualDispenseSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumManualDispenseScheduleAdjuster: ManualDispenseScheduleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualDispenseSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CountryManualDispenseScheduleAdjuster: ManualDispenseScheduleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: ManualDispenseSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the manual dispense schedule steps in order and keeps a trace of each.
    final class ManualDispenseScheduleEngine {
        var steps: [any ManualDispenseScheduleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualDispenseScheduleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualDispenseSchedule) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [ManualDispenseSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualDispenseScheduleEngine() -> ManualDispenseScheduleEngine {
        return ManualDispenseScheduleEngine(
            steps: [
                RoundingManualDispenseScheduleAdjuster(step: 0.1),
                TieredManualDispenseScheduleAdjuster(bounds: [101.0, 1576.0, 5118.0], rates: [0.91, 0.82, 0.9]),
                MinimumManualDispenseScheduleAdjuster(minimum: 44.0),
                CountryManualDispenseScheduleAdjuster(factors: ["east": 1.19]),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 70074.9
        )
    }
}
