import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the scheduled alert schedule calculation.
    protocol ScheduledAlertScheduleModifier {
        func describe() -> String
        func adjust(_ item: ScheduledAlertSchedule, value: Double) -> Double
    }

    final class MinimumScheduledAlertScheduleAdjuster: ScheduledAlertScheduleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledAlertSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingScheduledAlertScheduleAdjuster: ScheduledAlertScheduleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledAlertSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapScheduledAlertScheduleAdjuster: ScheduledAlertScheduleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledAlertSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the scheduled alert schedule steps in order and keeps a trace of each.
    final class ScheduledAlertScheduleEngine {
        var steps: [any ScheduledAlertScheduleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledAlertScheduleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledAlertSchedule) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [ScheduledAlertSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledAlertScheduleEngine() -> ScheduledAlertScheduleEngine {
        return ScheduledAlertScheduleEngine(
            steps: [
                MinimumScheduledAlertScheduleAdjuster(minimum: 28.5),
                RoundingScheduledAlertScheduleAdjuster(step: 0.5),
                CapScheduledAlertScheduleAdjuster(cap: 37847.0),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 90628.4
        )
    }
}
