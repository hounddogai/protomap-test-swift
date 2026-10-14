import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the substitution claim calculation.
    protocol SubstitutionClaimModifier {
        func describe() -> String
        func adjust(_ item: SubstitutionClaim, value: Double) -> Double
    }

    final class LabelSubstitutionClaimAdjuster: SubstitutionClaimModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: SubstitutionClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredSubstitutionClaimAdjuster: SubstitutionClaimModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SubstitutionClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedSubstitutionClaimAdjuster: SubstitutionClaimModifier {
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

        func adjust(_ item: SubstitutionClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSubstitutionClaimAdjuster: SubstitutionClaimModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SubstitutionClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingSubstitutionClaimAdjuster: SubstitutionClaimModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SubstitutionClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentSubstitutionClaimAdjuster: SubstitutionClaimModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SubstitutionClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the substitution claim steps in order and keeps a trace of each.
    final class SubstitutionClaimEngine {
        var steps: [any SubstitutionClaimModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SubstitutionClaimModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SubstitutionClaim) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [SubstitutionClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSubstitutionClaimEngine(_ flags: Kit.Flags.Registry) -> SubstitutionClaimEngine {
        return SubstitutionClaimEngine(
            steps: [
                LabelSubstitutionClaimAdjuster(factors: ["north": 1.07, "south": 1.3, "central": 1.38]),
                TieredSubstitutionClaimAdjuster(bounds: [3209.0, 3766.0, 7665.0], rates: [1.08, 0.97, 0.86]),
                FlaggedSubstitutionClaimAdjuster(flags: flags, flag: "substitution-claim-weighted", percent: 8.7),
                CapSubstitutionClaimAdjuster(cap: 19757.0),
                RoundingSubstitutionClaimAdjuster(step: 1.0),
                PercentSubstitutionClaimAdjuster(percent: -2.6),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 78368.8
        )
    }
}
