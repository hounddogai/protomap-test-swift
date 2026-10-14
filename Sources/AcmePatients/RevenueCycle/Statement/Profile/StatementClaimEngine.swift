import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the statement claim calculation.
    protocol StatementClaimAdjuster {
        func describe() -> String
        func adjust(_ item: StatementClaim, value: Double) -> Double
    }

    final class TitleStatementClaimAdjuster: StatementClaimAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: StatementClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class StatementClaimRetriesOffsetAdjuster: StatementClaimAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: StatementClaim, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class MinimumStatementClaimAdjuster: StatementClaimAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StatementClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapStatementClaimAdjuster: StatementClaimAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StatementClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the statement claim steps in order and keeps a trace of each.
    final class StatementClaimEngine {
        var steps: [any StatementClaimAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StatementClaimAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StatementClaim) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any StatementClaimAdjuster = steps[index]
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

        func evaluateAll(_ items: [StatementClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStatementClaimEngine() -> StatementClaimEngine {
        return StatementClaimEngine(
            steps: [
                TitleStatementClaimAdjuster(factors: ["west": 1.14, "south": 1.29]),
                StatementClaimRetriesOffsetAdjuster(weight: 1.03),
                MinimumStatementClaimAdjuster(minimum: 7.0),
                CapStatementClaimAdjuster(cap: 38980.0),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 20966.7
        )
    }
}
