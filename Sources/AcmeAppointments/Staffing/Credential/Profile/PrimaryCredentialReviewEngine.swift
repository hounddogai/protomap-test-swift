import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the primary credential review calculation.
    protocol PrimaryCredentialReviewFactor {
        func describe() -> String
        func adjust(_ item: PrimaryCredentialReview, value: Double) -> Double
    }

    final class CapPrimaryCredentialReviewAdjuster: PrimaryCredentialReviewFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryCredentialReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumPrimaryCredentialReviewAdjuster: PrimaryCredentialReviewFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryCredentialReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentPrimaryCredentialReviewAdjuster: PrimaryCredentialReviewFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryCredentialReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionPrimaryCredentialReviewAdjuster: PrimaryCredentialReviewFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: PrimaryCredentialReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PrimaryCredentialReviewEndsAtOffsetAdjuster: PrimaryCredentialReviewFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: PrimaryCredentialReview, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    /// Runs the primary credential review steps in order and keeps a trace of each.
    final class PrimaryCredentialReviewEngine {
        var steps: [any PrimaryCredentialReviewFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryCredentialReviewFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryCredentialReview) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [PrimaryCredentialReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryCredentialReviewEngine() -> PrimaryCredentialReviewEngine {
        return PrimaryCredentialReviewEngine(
            steps: [
                CapPrimaryCredentialReviewAdjuster(cap: 35249.0),
                MinimumPrimaryCredentialReviewAdjuster(minimum: 13.2),
                PercentPrimaryCredentialReviewAdjuster(percent: 7.8),
                RegionPrimaryCredentialReviewAdjuster(factors: ["north": 1.19]),
                PrimaryCredentialReviewEndsAtOffsetAdjuster(weight: 0.45),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 20124.5
        )
    }
}
