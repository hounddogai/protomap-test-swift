import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the rolling substitution claim calculation.
    protocol RollingSubstitutionClaimModifier {
        func describe() -> String
        func adjust(_ item: RollingSubstitutionClaim, value: Double) -> Double
    }

    final class MinimumRollingSubstitutionClaimAdjuster: RollingSubstitutionClaimModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingSubstitutionClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingRollingSubstitutionClaimAdjuster: RollingSubstitutionClaimModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingSubstitutionClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentRollingSubstitutionClaimAdjuster: RollingSubstitutionClaimModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingSubstitutionClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRollingSubstitutionClaimAdjuster: RollingSubstitutionClaimModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingSubstitutionClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the rolling substitution claim steps in order and keeps a trace of each.
    final class RollingSubstitutionClaimEngine {
        var steps: [any RollingSubstitutionClaimModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingSubstitutionClaimModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RollingSubstitutionClaim) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [RollingSubstitutionClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRollingSubstitutionClaimEngine() -> RollingSubstitutionClaimEngine {
        return RollingSubstitutionClaimEngine(
            steps: [
                MinimumRollingSubstitutionClaimAdjuster(minimum: 46.6),
                RoundingRollingSubstitutionClaimAdjuster(step: 0.1),
                PercentRollingSubstitutionClaimAdjuster(percent: 4.9),
                TieredRollingSubstitutionClaimAdjuster(bounds: [6015.0, 6873.0], rates: [1.16, 1.15]),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 92570.2
        )
    }
}
