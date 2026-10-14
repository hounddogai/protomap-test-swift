import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the tiered care gap schedule calculation.
    protocol TieredCareGapScheduleModifier {
        func describe() -> String
        func adjust(_ item: TieredCareGapSchedule, value: Double) -> Double
    }

    final class PercentTieredCareGapScheduleAdjuster: TieredCareGapScheduleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredCareGapSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredTieredCareGapScheduleAdjuster: TieredCareGapScheduleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredCareGapSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingTieredCareGapScheduleAdjuster: TieredCareGapScheduleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredCareGapSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredCareGapSchedulePriorityOffsetAdjuster: TieredCareGapScheduleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: TieredCareGapSchedule, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    /// Runs the tiered care gap schedule steps in order and keeps a trace of each.
    final class TieredCareGapScheduleEngine {
        var steps: [any TieredCareGapScheduleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredCareGapScheduleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredCareGapSchedule) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredCareGapScheduleModifier = steps[index]
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

        func evaluateAll(_ items: [TieredCareGapSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredCareGapScheduleEngine() -> TieredCareGapScheduleEngine {
        return TieredCareGapScheduleEngine(
            steps: [
                PercentTieredCareGapScheduleAdjuster(percent: -19.3),
                TieredTieredCareGapScheduleAdjuster(
                    bounds: [294.0, 1030.0, 8526.0, 8923.0],
                    rates: [0.99, 0.99, 0.89, 1.03]
                ),
                RoundingTieredCareGapScheduleAdjuster(step: 0.25),
                TieredCareGapSchedulePriorityOffsetAdjuster(weight: 1.33),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 65774.5
        )
    }
}
