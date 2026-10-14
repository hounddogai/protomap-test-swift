import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the scheduled isolation policy calculation.
    protocol ScheduledIsolationPolicyModifier {
        func describe() -> String
        func adjust(_ item: ScheduledIsolationPolicy, value: Double) -> Double
    }

    final class CapScheduledIsolationPolicyAdjuster: ScheduledIsolationPolicyModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledIsolationPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingScheduledIsolationPolicyAdjuster: ScheduledIsolationPolicyModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledIsolationPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredScheduledIsolationPolicyAdjuster: ScheduledIsolationPolicyModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledIsolationPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the scheduled isolation policy steps in order and keeps a trace of each.
    final class ScheduledIsolationPolicyEngine {
        var steps: [any ScheduledIsolationPolicyModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledIsolationPolicyModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledIsolationPolicy) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledIsolationPolicyModifier = steps[index]
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

        func evaluateAll(_ items: [ScheduledIsolationPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledIsolationPolicyEngine() -> ScheduledIsolationPolicyEngine {
        return ScheduledIsolationPolicyEngine(
            steps: [
                CapScheduledIsolationPolicyAdjuster(cap: 27714.0),
                RoundingScheduledIsolationPolicyAdjuster(step: 0.5),
                TieredScheduledIsolationPolicyAdjuster(bounds: [5135.0, 5292.0, 9626.0], rates: [0.87, 0.83, 0.91]),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 51226.5
        )
    }
}
