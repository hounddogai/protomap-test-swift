import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the default program override calculation.
    protocol DefaultProgramOverrideModifier {
        func describe() -> String
        func adjust(_ item: DefaultProgramOverride, value: Double) -> Double
    }

    final class MinimumDefaultProgramOverrideAdjuster: DefaultProgramOverrideModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultProgramOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedDefaultProgramOverrideAdjuster: DefaultProgramOverrideModifier {
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

        func adjust(_ item: DefaultProgramOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentDefaultProgramOverrideAdjuster: DefaultProgramOverrideModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultProgramOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DefaultProgramOverrideEndsAtOffsetAdjuster: DefaultProgramOverrideModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: DefaultProgramOverride, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class CapDefaultProgramOverrideAdjuster: DefaultProgramOverrideModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultProgramOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredDefaultProgramOverrideAdjuster: DefaultProgramOverrideModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultProgramOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the default program override steps in order and keeps a trace of each.
    final class DefaultProgramOverrideEngine {
        var steps: [any DefaultProgramOverrideModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultProgramOverrideModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultProgramOverride) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [DefaultProgramOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultProgramOverrideEngine(_ flags: Kit.Flags.Registry) -> DefaultProgramOverrideEngine {
        return DefaultProgramOverrideEngine(
            steps: [
                MinimumDefaultProgramOverrideAdjuster(minimum: 33.9),
                FlaggedDefaultProgramOverrideAdjuster(
                    flags: flags,
                    flag: "default-program-override-strict",
                    percent: -5.9
                ),
                PercentDefaultProgramOverrideAdjuster(percent: -19.1),
                DefaultProgramOverrideEndsAtOffsetAdjuster(weight: 1.79),
                CapDefaultProgramOverrideAdjuster(cap: 38360.0),
                TieredDefaultProgramOverrideAdjuster(bounds: [1869.0, 2016.0, 9525.0], rates: [1.13, 1.1, 1.07]),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 1082.2
        )
    }
}
