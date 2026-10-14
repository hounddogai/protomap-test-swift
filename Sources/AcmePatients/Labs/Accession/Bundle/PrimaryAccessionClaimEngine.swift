import AcmePlatform
import Foundation

extension Labs {
    /// One step of the primary accession claim calculation.
    protocol PrimaryAccessionClaimModifier {
        func describe() -> String
        func adjust(_ item: PrimaryAccessionClaim, value: Double) -> Double
    }

    final class TieredPrimaryAccessionClaimAdjuster: PrimaryAccessionClaimModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryAccessionClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumPrimaryAccessionClaimAdjuster: PrimaryAccessionClaimModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryAccessionClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CategoryPrimaryAccessionClaimAdjuster: PrimaryAccessionClaimModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: PrimaryAccessionClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingPrimaryAccessionClaimAdjuster: PrimaryAccessionClaimModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryAccessionClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the primary accession claim steps in order and keeps a trace of each.
    final class PrimaryAccessionClaimEngine {
        var steps: [any PrimaryAccessionClaimModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryAccessionClaimModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryAccessionClaim) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryAccessionClaimModifier = steps[index]
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

        func evaluateAll(_ items: [PrimaryAccessionClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryAccessionClaimEngine() -> PrimaryAccessionClaimEngine {
        return PrimaryAccessionClaimEngine(
            steps: [
                TieredPrimaryAccessionClaimAdjuster(bounds: [5591.0, 8176.0], rates: [1.0, 0.93]),
                MinimumPrimaryAccessionClaimAdjuster(minimum: 39.8),
                CategoryPrimaryAccessionClaimAdjuster(factors: ["central": 1.15, "retail": 0.78]),
                RoundingPrimaryAccessionClaimAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 38533.5
        )
    }
}
