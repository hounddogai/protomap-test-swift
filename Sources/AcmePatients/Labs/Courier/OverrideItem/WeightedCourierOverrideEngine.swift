import AcmePlatform
import Foundation

extension Labs {
    /// One step of the weighted courier override calculation.
    protocol WeightedCourierOverrideStep {
        func describe() -> String
        func adjust(_ item: WeightedCourierOverride, value: Double) -> Double
    }

    final class MinimumWeightedCourierOverrideAdjuster: WeightedCourierOverrideStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedCourierOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredWeightedCourierOverrideAdjuster: WeightedCourierOverrideStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedCourierOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedWeightedCourierOverrideAdjuster: WeightedCourierOverrideStep {
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

        func adjust(_ item: WeightedCourierOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted courier override steps in order and keeps a trace of each.
    final class WeightedCourierOverrideEngine {
        var steps: [any WeightedCourierOverrideStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedCourierOverrideStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WeightedCourierOverride) -> Double {
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

        func evaluateAll(_ items: [WeightedCourierOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWeightedCourierOverrideEngine(_ flags: Kit.Flags.Registry) -> WeightedCourierOverrideEngine {
        return WeightedCourierOverrideEngine(
            steps: [
                MinimumWeightedCourierOverrideAdjuster(minimum: 25.8),
                TieredWeightedCourierOverrideAdjuster(bounds: [633.0, 7315.0, 9958.0], rates: [0.98, 0.8, 0.91]),
                FlaggedWeightedCourierOverrideAdjuster(
                    flags: flags,
                    flag: "weighted-courier-override-seasonal",
                    percent: 2.7
                ),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 4054.4
        )
    }
}
