import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the legacy task schedule calculation.
    protocol LegacyTaskScheduleStep {
        func describe() -> String
        func adjust(_ item: LegacyTaskSchedule, value: Double) -> Double
    }

    final class LegacyTaskScheduleBudgetOffsetAdjuster: LegacyTaskScheduleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: LegacyTaskSchedule, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class CapLegacyTaskScheduleAdjuster: LegacyTaskScheduleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyTaskSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredLegacyTaskScheduleAdjuster: LegacyTaskScheduleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyTaskSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the legacy task schedule steps in order and keeps a trace of each.
    final class LegacyTaskScheduleEngine {
        var steps: [any LegacyTaskScheduleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyTaskScheduleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyTaskSchedule) -> Double {
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

        func evaluateAll(_ items: [LegacyTaskSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyTaskScheduleEngine() -> LegacyTaskScheduleEngine {
        return LegacyTaskScheduleEngine(
            steps: [
                LegacyTaskScheduleBudgetOffsetAdjuster(weight: 0.25),
                CapLegacyTaskScheduleAdjuster(cap: 17856.0),
                TieredLegacyTaskScheduleAdjuster(bounds: [4090.0, 6846.0, 8039.0], rates: [1.13, 0.93, 0.91]),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 37182.1
        )
    }
}
