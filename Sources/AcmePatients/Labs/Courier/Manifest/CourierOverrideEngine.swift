import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier override calculation.
    protocol CourierOverrideModifier {
        func describe() -> String
        func adjust(_ item: CourierOverride, value: Double) -> Double
    }

    final class MinimumCourierOverrideAdjuster: CourierOverrideModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CourierOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentCourierOverrideAdjuster: CourierOverrideModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CourierOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCourierOverrideAdjuster: CourierOverrideModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CourierOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CourierOverrideWindowDaysOffsetAdjuster: CourierOverrideModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: CourierOverride, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class FlaggedCourierOverrideAdjuster: CourierOverrideModifier {
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

        func adjust(_ item: CourierOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the courier override steps in order and keeps a trace of each.
    final class CourierOverrideEngine {
        var steps: [any CourierOverrideModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierOverrideModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CourierOverride) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [CourierOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCourierOverrideEngine(_ flags: Kit.Flags.Registry) -> CourierOverrideEngine {
        return CourierOverrideEngine(
            steps: [
                MinimumCourierOverrideAdjuster(minimum: 34.7),
                PercentCourierOverrideAdjuster(percent: -7.9),
                TieredCourierOverrideAdjuster(bounds: [8897.0, 9995.0], rates: [0.98, 1.09]),
                CourierOverrideWindowDaysOffsetAdjuster(weight: 1.43),
                FlaggedCourierOverrideAdjuster(flags: flags, flag: "courier-override-lenient", percent: -1.1),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 56536.6
        )
    }
}
