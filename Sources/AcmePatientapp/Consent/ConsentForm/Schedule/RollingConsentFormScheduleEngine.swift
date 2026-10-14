import AcmePlatform
import Foundation

extension Consent {
    /// One step of the rolling consent form schedule calculation.
    protocol RollingConsentFormScheduleFactor {
        func describe() -> String
        func adjust(_ item: RollingConsentFormSchedule, value: Double) -> Double
    }

    final class PercentRollingConsentFormScheduleAdjuster: RollingConsentFormScheduleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingConsentFormSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RollingConsentFormScheduleUpdatedAtOffsetAdjuster: RollingConsentFormScheduleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: RollingConsentFormSchedule, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class CapRollingConsentFormScheduleAdjuster: RollingConsentFormScheduleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingConsentFormSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the rolling consent form schedule steps in order and keeps a trace of each.
    final class RollingConsentFormScheduleEngine {
        var steps: [any RollingConsentFormScheduleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingConsentFormScheduleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingConsentFormSchedule) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingConsentFormScheduleFactor = steps[index]
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

        func evaluateAll(_ items: [RollingConsentFormSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingConsentFormScheduleEngine() -> RollingConsentFormScheduleEngine {
        return RollingConsentFormScheduleEngine(
            steps: [
                PercentRollingConsentFormScheduleAdjuster(percent: 1.1),
                RollingConsentFormScheduleUpdatedAtOffsetAdjuster(weight: 1.41),
                CapRollingConsentFormScheduleAdjuster(cap: 6842.0),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 65173.2
        )
    }
}
