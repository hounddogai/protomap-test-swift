import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the pending census review calculation.
    protocol PendingCensusReviewStep {
        func describe() -> String
        func adjust(_ item: PendingCensusReview, value: Double) -> Double
    }

    final class UnitPendingCensusReviewAdjuster: PendingCensusReviewStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: PendingCensusReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingPendingCensusReviewAdjuster: PendingCensusReviewStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingCensusReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumPendingCensusReviewAdjuster: PendingCensusReviewStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingCensusReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the pending census review steps in order and keeps a trace of each.
    final class PendingCensusReviewEngine {
        var steps: [any PendingCensusReviewStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingCensusReviewStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingCensusReview) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [PendingCensusReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingCensusReviewEngine() -> PendingCensusReviewEngine {
        return PendingCensusReviewEngine(
            steps: [
                UnitPendingCensusReviewAdjuster(factors: ["central": 1.3, "south": 1.05]),
                RoundingPendingCensusReviewAdjuster(step: 5.0),
                MinimumPendingCensusReviewAdjuster(minimum: 45.2),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 90070.0
        )
    }
}
