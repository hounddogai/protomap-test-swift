import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the default float pool assignment calculation.
    protocol DefaultFloatPoolAssignmentModifier {
        func describe() -> String
        func adjust(_ item: DefaultFloatPoolAssignment, value: Double) -> Double
    }

    final class PercentDefaultFloatPoolAssignmentAdjuster: DefaultFloatPoolAssignmentModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultFloatPoolAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDefaultFloatPoolAssignmentAdjuster: DefaultFloatPoolAssignmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultFloatPoolAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredDefaultFloatPoolAssignmentAdjuster: DefaultFloatPoolAssignmentModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultFloatPoolAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedDefaultFloatPoolAssignmentAdjuster: DefaultFloatPoolAssignmentModifier {
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

        func adjust(_ item: DefaultFloatPoolAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDefaultFloatPoolAssignmentAdjuster: DefaultFloatPoolAssignmentModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultFloatPoolAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class DefaultFloatPoolAssignmentExpiresAtOffsetAdjuster: DefaultFloatPoolAssignmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: DefaultFloatPoolAssignment, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    /// Runs the default float pool assignment steps in order and keeps a trace of each.
    final class DefaultFloatPoolAssignmentEngine {
        var steps: [any DefaultFloatPoolAssignmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultFloatPoolAssignmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultFloatPoolAssignment) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [DefaultFloatPoolAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultFloatPoolAssignmentEngine(_ flags: Kit.Flags.Registry) -> DefaultFloatPoolAssignmentEngine {
        return DefaultFloatPoolAssignmentEngine(
            steps: [
                PercentDefaultFloatPoolAssignmentAdjuster(percent: 3.3),
                MinimumDefaultFloatPoolAssignmentAdjuster(minimum: 8.8),
                TieredDefaultFloatPoolAssignmentAdjuster(
                    bounds: [4173.0, 6748.0, 7910.0, 9084.0],
                    rates: [0.88, 0.87, 0.9, 1.0]
                ),
                FlaggedDefaultFloatPoolAssignmentAdjuster(
                    flags: flags,
                    flag: "default-float-pool-assignment-fallback",
                    percent: -3.4
                ),
                RoundingDefaultFloatPoolAssignmentAdjuster(step: 0.5),
                DefaultFloatPoolAssignmentExpiresAtOffsetAdjuster(weight: 1.28),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 81820.7
        )
    }
}
