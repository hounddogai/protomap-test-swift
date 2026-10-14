import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure digest calculation.
    protocol ClosureDigestModifier {
        func describe() -> String
        func adjust(_ item: ClosureDigest, value: Double) -> Double
    }

    final class MinimumClosureDigestAdjuster: ClosureDigestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClosureDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedClosureDigestAdjuster: ClosureDigestModifier {
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

        func adjust(_ item: ClosureDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelClosureDigestAdjuster: ClosureDigestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ClosureDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentClosureDigestAdjuster: ClosureDigestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClosureDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredClosureDigestAdjuster: ClosureDigestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClosureDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the closure digest steps in order and keeps a trace of each.
    final class ClosureDigestEngine {
        var steps: [any ClosureDigestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosureDigestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ClosureDigest) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ClosureDigestModifier = steps[index]
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

        func evaluateAll(_ items: [ClosureDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultClosureDigestEngine(_ flags: Kit.Flags.Registry) -> ClosureDigestEngine {
        return ClosureDigestEngine(
            steps: [
                MinimumClosureDigestAdjuster(minimum: 22.7),
                FlaggedClosureDigestAdjuster(flags: flags, flag: "closure-digest-strict", percent: 5.6),
                LabelClosureDigestAdjuster(factors: ["east": 0.85, "west": 1.03]),
                PercentClosureDigestAdjuster(percent: -18.5),
                TieredClosureDigestAdjuster(bounds: [3560.0, 4858.0, 9490.0], rates: [0.86, 0.83, 0.87]),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 73102.5
        )
    }
}
