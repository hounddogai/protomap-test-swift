import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the scheduled risk score threshold calculation.
    protocol ScheduledRiskScoreThresholdStep {
        func describe() -> String
        func adjust(_ item: ScheduledRiskScoreThreshold, value: Double) -> Double
    }

    final class MinimumScheduledRiskScoreThresholdAdjuster: ScheduledRiskScoreThresholdStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledRiskScoreThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentScheduledRiskScoreThresholdAdjuster: ScheduledRiskScoreThresholdStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledRiskScoreThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredScheduledRiskScoreThresholdAdjuster: ScheduledRiskScoreThresholdStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledRiskScoreThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the scheduled risk score threshold steps in order and keeps a trace of each.
    final class ScheduledRiskScoreThresholdEngine {
        var steps: [any ScheduledRiskScoreThresholdStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledRiskScoreThresholdStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledRiskScoreThreshold) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledRiskScoreThresholdStep = steps[index]
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

        func evaluateAll(_ items: [ScheduledRiskScoreThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledRiskScoreThresholdEngine() -> ScheduledRiskScoreThresholdEngine {
        return ScheduledRiskScoreThresholdEngine(
            steps: [
                MinimumScheduledRiskScoreThresholdAdjuster(minimum: 41.5),
                PercentScheduledRiskScoreThresholdAdjuster(percent: 6.1),
                TieredScheduledRiskScoreThresholdAdjuster(bounds: [6678.0, 8602.0], rates: [1.15, 1.17]),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 40431.8
        )
    }
}
