import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the statement bundle calculation.
    protocol StatementBundleModifier {
        func describe() -> String
        func adjust(_ item: StatementBundle, value: Double) -> Double
    }

    final class PercentStatementBundleAdjuster: StatementBundleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StatementBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SegmentStatementBundleAdjuster: StatementBundleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: StatementBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumStatementBundleAdjuster: StatementBundleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StatementBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the statement bundle steps in order and keeps a trace of each.
    final class StatementBundleEngine {
        var steps: [any StatementBundleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StatementBundleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StatementBundle) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [StatementBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStatementBundleEngine() -> StatementBundleEngine {
        return StatementBundleEngine(
            steps: [
                PercentStatementBundleAdjuster(percent: 0.1),
                SegmentStatementBundleAdjuster(factors: ["retail": 1.26, "east": 0.95, "north": 0.73]),
                MinimumStatementBundleAdjuster(minimum: 18.3),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 18176.1
        )
    }
}
