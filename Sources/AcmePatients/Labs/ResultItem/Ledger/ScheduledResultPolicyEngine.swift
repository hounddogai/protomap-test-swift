import AcmePlatform
import Foundation

extension Labs {
    /// One step of the scheduled result policy calculation.
    protocol ScheduledResultPolicyModifier {
        func describe() -> String
        func adjust(_ item: ScheduledResultPolicy, value: Double) -> Double
    }

    final class TieredScheduledResultPolicyAdjuster: ScheduledResultPolicyModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledResultPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ScheduledResultPolicyScoreOffsetAdjuster: ScheduledResultPolicyModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: ScheduledResultPolicy, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class MinimumScheduledResultPolicyAdjuster: ScheduledResultPolicyModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledResultPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the scheduled result policy steps in order and keeps a trace of each.
    final class ScheduledResultPolicyEngine {
        var steps: [any ScheduledResultPolicyModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledResultPolicyModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledResultPolicy) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [ScheduledResultPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledResultPolicyEngine() -> ScheduledResultPolicyEngine {
        return ScheduledResultPolicyEngine(
            steps: [
                TieredScheduledResultPolicyAdjuster(bounds: [838.0, 3339.0], rates: [1.13, 0.96]),
                ScheduledResultPolicyScoreOffsetAdjuster(weight: 1.43),
                MinimumScheduledResultPolicyAdjuster(minimum: 46.0),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 9490.1
        )
    }
}
