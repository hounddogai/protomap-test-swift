import AcmePlatform
import Foundation

extension Consent {
    /// One step of the scheduled revocation exception calculation.
    protocol ScheduledRevocationExceptionAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledRevocationException, value: Double) -> Double
    }

    final class TieredScheduledRevocationExceptionAdjuster: ScheduledRevocationExceptionAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledRevocationException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingScheduledRevocationExceptionAdjuster: ScheduledRevocationExceptionAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledRevocationException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentScheduledRevocationExceptionAdjuster: ScheduledRevocationExceptionAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledRevocationException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumScheduledRevocationExceptionAdjuster: ScheduledRevocationExceptionAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledRevocationException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the scheduled revocation exception steps in order and keeps a trace of each.
    final class ScheduledRevocationExceptionEngine {
        var steps: [any ScheduledRevocationExceptionAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledRevocationExceptionAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledRevocationException) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledRevocationExceptionAdjuster = steps[index]
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

        func evaluateAll(_ items: [ScheduledRevocationException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledRevocationExceptionEngine() -> ScheduledRevocationExceptionEngine {
        return ScheduledRevocationExceptionEngine(
            steps: [
                TieredScheduledRevocationExceptionAdjuster(bounds: [251.0, 1965.0, 4243.0], rates: [0.86, 0.85, 1.02]),
                RoundingScheduledRevocationExceptionAdjuster(step: 0.05),
                PercentScheduledRevocationExceptionAdjuster(percent: 14.1),
                MinimumScheduledRevocationExceptionAdjuster(minimum: 22.8),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 14136.2
        )
    }
}
