import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the legacy substitution claim calculation.
    protocol LegacySubstitutionClaimModifier {
        func describe() -> String
        func adjust(_ item: LegacySubstitutionClaim, value: Double) -> Double
    }

    final class CapLegacySubstitutionClaimAdjuster: LegacySubstitutionClaimModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacySubstitutionClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleLegacySubstitutionClaimAdjuster: LegacySubstitutionClaimModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LegacySubstitutionClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class LegacySubstitutionClaimScoreOffsetAdjuster: LegacySubstitutionClaimModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: LegacySubstitutionClaim, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    /// Runs the legacy substitution claim steps in order and keeps a trace of each.
    final class LegacySubstitutionClaimEngine {
        var steps: [any LegacySubstitutionClaimModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacySubstitutionClaimModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacySubstitutionClaim) -> Double {
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

        func evaluateAll(_ items: [LegacySubstitutionClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacySubstitutionClaimEngine() -> LegacySubstitutionClaimEngine {
        return LegacySubstitutionClaimEngine(
            steps: [
                CapLegacySubstitutionClaimAdjuster(cap: 7083.0),
                TitleLegacySubstitutionClaimAdjuster(factors: ["retail": 1.21, "west": 1.11]),
                LegacySubstitutionClaimScoreOffsetAdjuster(weight: 0.2),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 90183.7
        )
    }
}
