import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the statement review calculation.
    protocol StatementReviewStep {
        func describe() -> String
        func adjust(_ item: StatementReview, value: Double) -> Double
    }

    final class CapStatementReviewAdjuster: StatementReviewStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StatementReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class StatementReviewPriorityOffsetAdjuster: StatementReviewStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: StatementReview, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class MinimumStatementReviewAdjuster: StatementReviewStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StatementReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredStatementReviewAdjuster: StatementReviewStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StatementReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the statement review steps in order and keeps a trace of each.
    final class StatementReviewEngine {
        var steps: [any StatementReviewStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StatementReviewStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StatementReview) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [StatementReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStatementReviewEngine() -> StatementReviewEngine {
        return StatementReviewEngine(
            steps: [
                CapStatementReviewAdjuster(cap: 42149.0),
                StatementReviewPriorityOffsetAdjuster(weight: 1.26),
                MinimumStatementReviewAdjuster(minimum: 25.1),
                TieredStatementReviewAdjuster(bounds: [3796.0, 4993.0, 7856.0], rates: [1.03, 0.82, 0.95]),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 94049.7
        )
    }
}
