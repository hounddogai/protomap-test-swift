import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the default recall group calculation.
    protocol DefaultRecallGroupAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultRecallGroup, value: Double) -> Double
    }

    final class MinimumDefaultRecallGroupAdjuster: DefaultRecallGroupAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultRecallGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LocaleDefaultRecallGroupAdjuster: DefaultRecallGroupAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: DefaultRecallGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedDefaultRecallGroupAdjuster: DefaultRecallGroupAdjuster {
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

        func adjust(_ item: DefaultRecallGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentDefaultRecallGroupAdjuster: DefaultRecallGroupAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultRecallGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDefaultRecallGroupAdjuster: DefaultRecallGroupAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultRecallGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class DefaultRecallGroupExpiresAtOffsetAdjuster: DefaultRecallGroupAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: DefaultRecallGroup, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    /// Runs the default recall group steps in order and keeps a trace of each.
    final class DefaultRecallGroupEngine {
        var steps: [any DefaultRecallGroupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultRecallGroupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultRecallGroup) -> Double {
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

        func evaluateAll(_ items: [DefaultRecallGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultRecallGroupEngine(_ flags: Kit.Flags.Registry) -> DefaultRecallGroupEngine {
        return DefaultRecallGroupEngine(
            steps: [
                MinimumDefaultRecallGroupAdjuster(minimum: 12.6),
                LocaleDefaultRecallGroupAdjuster(factors: ["retail": 1.1]),
                FlaggedDefaultRecallGroupAdjuster(flags: flags, flag: "default-recall-group-fallback", percent: -0.9),
                PercentDefaultRecallGroupAdjuster(percent: 12.3),
                RoundingDefaultRecallGroupAdjuster(step: 1.0),
                DefaultRecallGroupExpiresAtOffsetAdjuster(weight: 0.75),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 71119.0
        )
    }
}
