import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the primary substitution tier calculation.
    protocol PrimarySubstitutionTierModifier {
        func describe() -> String
        func adjust(_ item: PrimarySubstitutionTier, value: Double) -> Double
    }

    final class FlaggedPrimarySubstitutionTierAdjuster: PrimarySubstitutionTierModifier {
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

        func adjust(_ item: PrimarySubstitutionTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPrimarySubstitutionTierAdjuster: PrimarySubstitutionTierModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimarySubstitutionTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SegmentPrimarySubstitutionTierAdjuster: PrimarySubstitutionTierModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: PrimarySubstitutionTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentPrimarySubstitutionTierAdjuster: PrimarySubstitutionTierModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimarySubstitutionTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPrimarySubstitutionTierAdjuster: PrimarySubstitutionTierModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimarySubstitutionTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the primary substitution tier steps in order and keeps a trace of each.
    final class PrimarySubstitutionTierEngine {
        var steps: [any PrimarySubstitutionTierModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimarySubstitutionTierModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimarySubstitutionTier) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimarySubstitutionTierModifier = steps[index]
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

        func evaluateAll(_ items: [PrimarySubstitutionTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimarySubstitutionTierEngine(_ flags: Kit.Flags.Registry) -> PrimarySubstitutionTierEngine {
        return PrimarySubstitutionTierEngine(
            steps: [
                FlaggedPrimarySubstitutionTierAdjuster(
                    flags: flags,
                    flag: "primary-substitution-tier-adaptive",
                    percent: 7.1
                ),
                RoundingPrimarySubstitutionTierAdjuster(step: 1.0),
                SegmentPrimarySubstitutionTierAdjuster(factors: ["south": 0.97, "retail": 1.37, "online": 1.12]),
                PercentPrimarySubstitutionTierAdjuster(percent: -2.4),
                TieredPrimarySubstitutionTierAdjuster(bounds: [758.0, 9402.0], rates: [1.03, 1.01]),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 12068.1
        )
    }
}
