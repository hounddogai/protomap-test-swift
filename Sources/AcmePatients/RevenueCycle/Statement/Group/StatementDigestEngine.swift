import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the statement digest calculation.
    protocol StatementDigestStep {
        func describe() -> String
        func adjust(_ item: StatementDigest, value: Double) -> Double
    }

    final class CapStatementDigestAdjuster: StatementDigestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StatementDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentStatementDigestAdjuster: StatementDigestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StatementDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingStatementDigestAdjuster: StatementDigestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StatementDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class StatementDigestStartsAtOffsetAdjuster: StatementDigestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: StatementDigest, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class MinimumStatementDigestAdjuster: StatementDigestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StatementDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelStatementDigestAdjuster: StatementDigestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: StatementDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the statement digest steps in order and keeps a trace of each.
    final class StatementDigestEngine {
        var steps: [any StatementDigestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StatementDigestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StatementDigest) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [StatementDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStatementDigestEngine() -> StatementDigestEngine {
        return StatementDigestEngine(
            steps: [
                CapStatementDigestAdjuster(cap: 35574.0),
                PercentStatementDigestAdjuster(percent: -21.2),
                RoundingStatementDigestAdjuster(step: 0.25),
                StatementDigestStartsAtOffsetAdjuster(weight: 1.82),
                MinimumStatementDigestAdjuster(minimum: 31.7),
                LabelStatementDigestAdjuster(factors: ["retail": 1.2, "north": 0.84, "central": 0.75]),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 11681.9
        )
    }
}
