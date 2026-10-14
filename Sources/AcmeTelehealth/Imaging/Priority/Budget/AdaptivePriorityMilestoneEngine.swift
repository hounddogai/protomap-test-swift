import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the adaptive priority milestone calculation.
    protocol AdaptivePriorityMilestoneModifier {
        func describe() -> String
        func adjust(_ item: AdaptivePriorityMilestone, value: Double) -> Double
    }

    final class MinimumAdaptivePriorityMilestoneAdjuster: AdaptivePriorityMilestoneModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptivePriorityMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class AdaptivePriorityMilestoneUpdatedAtOffsetAdjuster: AdaptivePriorityMilestoneModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: AdaptivePriorityMilestone, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class PercentAdaptivePriorityMilestoneAdjuster: AdaptivePriorityMilestoneModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptivePriorityMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive priority milestone steps in order and keeps a trace of each.
    final class AdaptivePriorityMilestoneEngine {
        var steps: [any AdaptivePriorityMilestoneModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptivePriorityMilestoneModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptivePriorityMilestone) -> Double {
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

        func evaluateAll(_ items: [AdaptivePriorityMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptivePriorityMilestoneEngine() -> AdaptivePriorityMilestoneEngine {
        return AdaptivePriorityMilestoneEngine(
            steps: [
                MinimumAdaptivePriorityMilestoneAdjuster(minimum: 35.3),
                AdaptivePriorityMilestoneUpdatedAtOffsetAdjuster(weight: 0.24),
                PercentAdaptivePriorityMilestoneAdjuster(percent: 4.2),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 61875.8
        )
    }
}
