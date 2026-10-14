import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier schedule calculation.
    protocol CourierScheduleFactor {
        func describe() -> String
        func adjust(_ item: CourierSchedule, value: Double) -> Double
    }

    final class PercentCourierScheduleAdjuster: CourierScheduleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CourierSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CourierScheduleCostOffsetAdjuster: CourierScheduleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: CourierSchedule, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class CapCourierScheduleAdjuster: CourierScheduleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CourierSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the courier schedule steps in order and keeps a trace of each.
    final class CourierScheduleEngine {
        var steps: [any CourierScheduleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierScheduleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CourierSchedule) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [CourierSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCourierScheduleEngine() -> CourierScheduleEngine {
        return CourierScheduleEngine(
            steps: [
                PercentCourierScheduleAdjuster(percent: -15.3),
                CourierScheduleCostOffsetAdjuster(weight: 1.62),
                CapCourierScheduleAdjuster(cap: 25503.0),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 41776.0
        )
    }
}
