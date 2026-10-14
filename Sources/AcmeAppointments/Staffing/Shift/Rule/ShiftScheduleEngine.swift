import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the shift schedule calculation.
    protocol ShiftScheduleModifier {
        func describe() -> String
        func adjust(_ item: ShiftSchedule, value: Double) -> Double
    }

    final class ShiftScheduleThresholdOffsetAdjuster: ShiftScheduleModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: ShiftSchedule, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class RegionShiftScheduleAdjuster: ShiftScheduleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: ShiftSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredShiftScheduleAdjuster: ShiftScheduleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ShiftSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentShiftScheduleAdjuster: ShiftScheduleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ShiftSchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedShiftScheduleAdjuster: ShiftScheduleModifier {
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

        func adjust(_ item: ShiftSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumShiftScheduleAdjuster: ShiftScheduleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ShiftSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the shift schedule steps in order and keeps a trace of each.
    final class ShiftScheduleEngine {
        var steps: [any ShiftScheduleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ShiftScheduleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ShiftSchedule) -> Double {
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

        func evaluateAll(_ items: [ShiftSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultShiftScheduleEngine(_ flags: Kit.Flags.Registry) -> ShiftScheduleEngine {
        return ShiftScheduleEngine(
            steps: [
                ShiftScheduleThresholdOffsetAdjuster(weight: 0.95),
                RegionShiftScheduleAdjuster(factors: ["online": 1.17]),
                TieredShiftScheduleAdjuster(bounds: [510.0, 713.0, 1446.0, 9294.0], rates: [1.17, 0.96, 1.06, 1.17]),
                PercentShiftScheduleAdjuster(percent: 23.5),
                FlaggedShiftScheduleAdjuster(flags: flags, flag: "shift-schedule-weighted", percent: 1.7),
                MinimumShiftScheduleAdjuster(minimum: 36.9),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 37688.1
        )
    }
}
