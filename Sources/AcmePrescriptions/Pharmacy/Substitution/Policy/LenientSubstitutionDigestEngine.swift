import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the lenient substitution digest calculation.
    protocol LenientSubstitutionDigestModifier {
        func describe() -> String
        func adjust(_ item: LenientSubstitutionDigest, value: Double) -> Double
    }

    final class RoundingLenientSubstitutionDigestAdjuster: LenientSubstitutionDigestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientSubstitutionDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CategoryLenientSubstitutionDigestAdjuster: LenientSubstitutionDigestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: LenientSubstitutionDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredLenientSubstitutionDigestAdjuster: LenientSubstitutionDigestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientSubstitutionDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentLenientSubstitutionDigestAdjuster: LenientSubstitutionDigestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientSubstitutionDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedLenientSubstitutionDigestAdjuster: LenientSubstitutionDigestModifier {
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

        func adjust(_ item: LenientSubstitutionDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLenientSubstitutionDigestAdjuster: LenientSubstitutionDigestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientSubstitutionDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the lenient substitution digest steps in order and keeps a trace of each.
    final class LenientSubstitutionDigestEngine {
        var steps: [any LenientSubstitutionDigestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientSubstitutionDigestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientSubstitutionDigest) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientSubstitutionDigestModifier = steps[index]
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

        func evaluateAll(_ items: [LenientSubstitutionDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientSubstitutionDigestEngine(_ flags: Kit.Flags.Registry) -> LenientSubstitutionDigestEngine {
        return LenientSubstitutionDigestEngine(
            steps: [
                RoundingLenientSubstitutionDigestAdjuster(step: 0.05),
                CategoryLenientSubstitutionDigestAdjuster(factors: ["north": 0.76, "online": 1.09]),
                TieredLenientSubstitutionDigestAdjuster(
                    bounds: [1280.0, 5912.0, 6910.0, 9556.0],
                    rates: [0.82, 0.97, 0.94, 0.82]
                ),
                PercentLenientSubstitutionDigestAdjuster(percent: -18.0),
                FlaggedLenientSubstitutionDigestAdjuster(
                    flags: flags,
                    flag: "lenient-substitution-digest-rolling",
                    percent: 0.8
                ),
                MinimumLenientSubstitutionDigestAdjuster(minimum: 34.7),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 19165.1
        )
    }
}
