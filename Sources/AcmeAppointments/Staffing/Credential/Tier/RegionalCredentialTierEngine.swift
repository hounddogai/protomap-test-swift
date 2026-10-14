import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the regional credential tier calculation.
    protocol RegionalCredentialTierModifier {
        func describe() -> String
        func adjust(_ item: RegionalCredentialTier, value: Double) -> Double
    }

    final class PercentRegionalCredentialTierAdjuster: RegionalCredentialTierModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalCredentialTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LocaleRegionalCredentialTierAdjuster: RegionalCredentialTierModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: RegionalCredentialTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredRegionalCredentialTierAdjuster: RegionalCredentialTierModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalCredentialTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RegionalCredentialTierQuantityOffsetAdjuster: RegionalCredentialTierModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: RegionalCredentialTier, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class FlaggedRegionalCredentialTierAdjuster: RegionalCredentialTierModifier {
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

        func adjust(_ item: RegionalCredentialTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRegionalCredentialTierAdjuster: RegionalCredentialTierModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalCredentialTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the regional credential tier steps in order and keeps a trace of each.
    final class RegionalCredentialTierEngine {
        var steps: [any RegionalCredentialTierModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalCredentialTierModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalCredentialTier) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalCredentialTierModifier = steps[index]
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

        func evaluateAll(_ items: [RegionalCredentialTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalCredentialTierEngine(_ flags: Kit.Flags.Registry) -> RegionalCredentialTierEngine {
        return RegionalCredentialTierEngine(
            steps: [
                PercentRegionalCredentialTierAdjuster(percent: -21.7),
                LocaleRegionalCredentialTierAdjuster(factors: ["east": 0.91, "west": 1.32]),
                TieredRegionalCredentialTierAdjuster(bounds: [245.0, 9015.0], rates: [1.13, 0.98]),
                RegionalCredentialTierQuantityOffsetAdjuster(weight: 0.61),
                FlaggedRegionalCredentialTierAdjuster(
                    flags: flags,
                    flag: "regional-credential-tier-weighted",
                    percent: 7.8
                ),
                RoundingRegionalCredentialTierAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 87622.0
        )
    }
}
