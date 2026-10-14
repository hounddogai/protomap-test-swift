import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the statement milestone calculation.
    protocol StatementMilestoneModifier {
        func describe() -> String
        func adjust(_ item: StatementMilestone, value: Double) -> Double
    }

    final class TieredStatementMilestoneAdjuster: StatementMilestoneModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StatementMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class StatementMilestoneThresholdOffsetAdjuster: StatementMilestoneModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: StatementMilestone, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class PercentStatementMilestoneAdjuster: StatementMilestoneModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StatementMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the statement milestone steps in order and keeps a trace of each.
    final class StatementMilestoneEngine {
        var steps: [any StatementMilestoneModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StatementMilestoneModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StatementMilestone) -> Double {
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

        func evaluateAll(_ items: [StatementMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStatementMilestoneEngine() -> StatementMilestoneEngine {
        return StatementMilestoneEngine(
            steps: [
                TieredStatementMilestoneAdjuster(bounds: [8913.0, 9220.0], rates: [1.01, 1.11]),
                StatementMilestoneThresholdOffsetAdjuster(weight: 0.43),
                PercentStatementMilestoneAdjuster(percent: -23.7),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 35061.0
        )
    }
}
