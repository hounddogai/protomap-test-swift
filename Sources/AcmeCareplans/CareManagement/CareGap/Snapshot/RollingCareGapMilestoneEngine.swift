import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the rolling care gap milestone calculation.
    protocol RollingCareGapMilestoneFactor {
        func describe() -> String
        func adjust(_ item: RollingCareGapMilestone, value: Double) -> Double
    }

    final class WardRollingCareGapMilestoneAdjuster: RollingCareGapMilestoneFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: RollingCareGapMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRollingCareGapMilestoneAdjuster: RollingCareGapMilestoneFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingCareGapMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentRollingCareGapMilestoneAdjuster: RollingCareGapMilestoneFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingCareGapMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rolling care gap milestone steps in order and keeps a trace of each.
    final class RollingCareGapMilestoneEngine {
        var steps: [any RollingCareGapMilestoneFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingCareGapMilestoneFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RollingCareGapMilestone) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingCareGapMilestoneFactor = steps[index]
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

        func evaluateAll(_ items: [RollingCareGapMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRollingCareGapMilestoneEngine() -> RollingCareGapMilestoneEngine {
        return RollingCareGapMilestoneEngine(
            steps: [
                WardRollingCareGapMilestoneAdjuster(factors: ["north": 0.76, "west": 1.07, "online": 1.19]),
                MinimumRollingCareGapMilestoneAdjuster(minimum: 1.0),
                PercentRollingCareGapMilestoneAdjuster(percent: 24.4),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 1056.9
        )
    }
}
