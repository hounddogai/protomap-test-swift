import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the default substitution tier calculation.
    protocol DefaultSubstitutionTierStep {
        func describe() -> String
        func adjust(_ item: DefaultSubstitutionTier, value: Double) -> Double
    }

    final class FlaggedDefaultSubstitutionTierAdjuster: DefaultSubstitutionTierStep {
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

        func adjust(_ item: DefaultSubstitutionTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDefaultSubstitutionTierAdjuster: DefaultSubstitutionTierStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultSubstitutionTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredDefaultSubstitutionTierAdjuster: DefaultSubstitutionTierStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultSubstitutionTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the default substitution tier steps in order and keeps a trace of each.
    final class DefaultSubstitutionTierEngine {
        var steps: [any DefaultSubstitutionTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultSubstitutionTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DefaultSubstitutionTier) -> Double {
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

        func evaluateAll(_ items: [DefaultSubstitutionTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDefaultSubstitutionTierEngine(_ flags: Kit.Flags.Registry) -> DefaultSubstitutionTierEngine {
        return DefaultSubstitutionTierEngine(
            steps: [
                FlaggedDefaultSubstitutionTierAdjuster(
                    flags: flags,
                    flag: "default-substitution-tier-legacy",
                    percent: -6.8
                ),
                MinimumDefaultSubstitutionTierAdjuster(minimum: 35.5),
                TieredDefaultSubstitutionTierAdjuster(
                    bounds: [2709.0, 4928.0, 5704.0, 7282.0],
                    rates: [0.97, 1.1, 1.17, 1.0]
                ),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 4269.5
        )
    }
}
