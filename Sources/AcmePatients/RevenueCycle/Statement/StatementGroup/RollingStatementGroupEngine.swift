import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the rolling statement group calculation.
    protocol RollingStatementGroupModifier {
        func describe() -> String
        func adjust(_ item: RollingStatementGroup, value: Double) -> Double
    }

    final class CapRollingStatementGroupAdjuster: RollingStatementGroupModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingStatementGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumRollingStatementGroupAdjuster: RollingStatementGroupModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingStatementGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedRollingStatementGroupAdjuster: RollingStatementGroupModifier {
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

        func adjust(_ item: RollingStatementGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RollingStatementGroupAcuityOffsetAdjuster: RollingStatementGroupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: RollingStatementGroup, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class WardRollingStatementGroupAdjuster: RollingStatementGroupModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: RollingStatementGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredRollingStatementGroupAdjuster: RollingStatementGroupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingStatementGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the rolling statement group steps in order and keeps a trace of each.
    final class RollingStatementGroupEngine {
        var steps: [any RollingStatementGroupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingStatementGroupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingStatementGroup) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingStatementGroupModifier = steps[index]
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

        func evaluateAll(_ items: [RollingStatementGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingStatementGroupEngine(_ flags: Kit.Flags.Registry) -> RollingStatementGroupEngine {
        return RollingStatementGroupEngine(
            steps: [
                CapRollingStatementGroupAdjuster(cap: 3047.0),
                MinimumRollingStatementGroupAdjuster(minimum: 25.6),
                FlaggedRollingStatementGroupAdjuster(
                    flags: flags,
                    flag: "rolling-statement-group-capped",
                    percent: 8.1
                ),
                RollingStatementGroupAcuityOffsetAdjuster(weight: 1.83),
                WardRollingStatementGroupAdjuster(factors: ["south": 1.15]),
                TieredRollingStatementGroupAdjuster(
                    bounds: [111.0, 672.0, 1535.0, 8147.0],
                    rates: [1.11, 1.15, 1.05, 1.06]
                ),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 38502.9
        )
    }
}
