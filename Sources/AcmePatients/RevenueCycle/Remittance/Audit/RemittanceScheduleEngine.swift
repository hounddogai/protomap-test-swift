import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance schedule calculation.
    protocol RemittanceScheduleStep {
        func describe() -> String
        func adjust(_ item: RemittanceSchedule, value: Double) -> Double
    }

    final class FlaggedRemittanceScheduleAdjuster: RemittanceScheduleStep {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: RemittanceSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRemittanceScheduleAdjuster: RemittanceScheduleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RemittanceSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RemittanceScheduleDurationMinutesOffsetAdjuster: RemittanceScheduleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: RemittanceSchedule, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class MinimumRemittanceScheduleAdjuster: RemittanceScheduleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RemittanceSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the remittance schedule steps in order and keeps a trace of each.
    final class RemittanceScheduleEngine {
        var steps: [any RemittanceScheduleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceScheduleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RemittanceSchedule) -> Double {
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

        func evaluateAll(_ items: [RemittanceSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRemittanceScheduleEngine(_ flags: Kit.Flags.Registry) -> RemittanceScheduleEngine {
        return RemittanceScheduleEngine(
            steps: [
                FlaggedRemittanceScheduleAdjuster(flags: flags, flag: "remittance-schedule-seasonal", percent: 9.2),
                TieredRemittanceScheduleAdjuster(bounds: [774.0, 4212.0, 7777.0], rates: [1.0, 1.11, 1.05]),
                RemittanceScheduleDurationMinutesOffsetAdjuster(weight: 1.42),
                MinimumRemittanceScheduleAdjuster(minimum: 23.3),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 53467.3
        )
    }
}
