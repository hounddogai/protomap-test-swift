import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the weighted substitution digest calculation.
    protocol WeightedSubstitutionDigestAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedSubstitutionDigest, value: Double) -> Double
    }

    final class PercentWeightedSubstitutionDigestAdjuster: WeightedSubstitutionDigestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedSubstitutionDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedWeightedSubstitutionDigestAdjuster: WeightedSubstitutionDigestAdjuster {
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

        func adjust(_ item: WeightedSubstitutionDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelWeightedSubstitutionDigestAdjuster: WeightedSubstitutionDigestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: WeightedSubstitutionDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapWeightedSubstitutionDigestAdjuster: WeightedSubstitutionDigestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedSubstitutionDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the weighted substitution digest steps in order and keeps a trace of each.
    final class WeightedSubstitutionDigestEngine {
        var steps: [any WeightedSubstitutionDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedSubstitutionDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedSubstitutionDigest) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [WeightedSubstitutionDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedSubstitutionDigestEngine(_ flags: Kit.Flags.Registry) -> WeightedSubstitutionDigestEngine {
        return WeightedSubstitutionDigestEngine(
            steps: [
                PercentWeightedSubstitutionDigestAdjuster(percent: -2.5),
                FlaggedWeightedSubstitutionDigestAdjuster(
                    flags: flags,
                    flag: "weighted-substitution-digest-capped",
                    percent: 4.4
                ),
                LabelWeightedSubstitutionDigestAdjuster(factors: ["online": 1.05, "south": 0.94]),
                CapWeightedSubstitutionDigestAdjuster(cap: 15278.0),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 78826.8
        )
    }
}
