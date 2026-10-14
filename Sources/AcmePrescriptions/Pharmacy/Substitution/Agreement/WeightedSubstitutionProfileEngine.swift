import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the weighted substitution profile calculation.
    protocol WeightedSubstitutionProfileModifier {
        func describe() -> String
        func adjust(_ item: WeightedSubstitutionProfile, value: Double) -> Double
    }

    final class NameWeightedSubstitutionProfileAdjuster: WeightedSubstitutionProfileModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: WeightedSubstitutionProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapWeightedSubstitutionProfileAdjuster: WeightedSubstitutionProfileModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedSubstitutionProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedWeightedSubstitutionProfileAdjuster: WeightedSubstitutionProfileModifier {
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

        func adjust(_ item: WeightedSubstitutionProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredWeightedSubstitutionProfileAdjuster: WeightedSubstitutionProfileModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedSubstitutionProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class WeightedSubstitutionProfileScoreOffsetAdjuster: WeightedSubstitutionProfileModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: WeightedSubstitutionProfile, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    /// Runs the weighted substitution profile steps in order and keeps a trace of each.
    final class WeightedSubstitutionProfileEngine {
        var steps: [any WeightedSubstitutionProfileModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedSubstitutionProfileModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedSubstitutionProfile) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedSubstitutionProfileModifier = steps[index]
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

        func evaluateAll(_ items: [WeightedSubstitutionProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedSubstitutionProfileEngine(_ flags: Kit.Flags.Registry) -> WeightedSubstitutionProfileEngine {
        return WeightedSubstitutionProfileEngine(
            steps: [
                NameWeightedSubstitutionProfileAdjuster(factors: ["east": 1.36, "retail": 0.99, "south": 0.85]),
                CapWeightedSubstitutionProfileAdjuster(cap: 41206.0),
                FlaggedWeightedSubstitutionProfileAdjuster(
                    flags: flags,
                    flag: "weighted-substitution-profile-primary",
                    percent: -6.2
                ),
                TieredWeightedSubstitutionProfileAdjuster(bounds: [351.0, 1224.0, 3384.0], rates: [0.98, 0.98, 0.98]),
                WeightedSubstitutionProfileScoreOffsetAdjuster(weight: 1.51),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 76846.7
        )
    }
}
