import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the substitution rollup calculation.
    protocol SubstitutionRollupAdjuster {
        func describe() -> String
        func adjust(_ item: SubstitutionRollup, value: Double) -> Double
    }

    final class MinimumSubstitutionRollupAdjuster: SubstitutionRollupAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SubstitutionRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentSubstitutionRollupAdjuster: SubstitutionRollupAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SubstitutionRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedSubstitutionRollupAdjuster: SubstitutionRollupAdjuster {
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

        func adjust(_ item: SubstitutionRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class UnitSubstitutionRollupAdjuster: SubstitutionRollupAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: SubstitutionRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the substitution rollup steps in order and keeps a trace of each.
    final class SubstitutionRollupEngine {
        var steps: [any SubstitutionRollupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SubstitutionRollupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SubstitutionRollup) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any SubstitutionRollupAdjuster = steps[index]
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

        func evaluateAll(_ items: [SubstitutionRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSubstitutionRollupEngine(_ flags: Kit.Flags.Registry) -> SubstitutionRollupEngine {
        return SubstitutionRollupEngine(
            steps: [
                MinimumSubstitutionRollupAdjuster(minimum: 0.4),
                PercentSubstitutionRollupAdjuster(percent: 13.8),
                FlaggedSubstitutionRollupAdjuster(flags: flags, flag: "substitution-rollup-seasonal", percent: -4.2),
                UnitSubstitutionRollupAdjuster(factors: ["central": 1.04, "south": 1.32, "west": 1.09]),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 73515.8
        )
    }
}
