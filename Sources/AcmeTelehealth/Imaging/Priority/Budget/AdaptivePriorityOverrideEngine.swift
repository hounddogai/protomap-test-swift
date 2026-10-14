import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the adaptive priority override calculation.
    protocol AdaptivePriorityOverrideFactor {
        func describe() -> String
        func adjust(_ item: AdaptivePriorityOverride, value: Double) -> Double
    }

    final class PercentAdaptivePriorityOverrideAdjuster: AdaptivePriorityOverrideFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptivePriorityOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AdaptivePriorityOverrideExpiresAtOffsetAdjuster: AdaptivePriorityOverrideFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: AdaptivePriorityOverride, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class RoundingAdaptivePriorityOverrideAdjuster: AdaptivePriorityOverrideFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptivePriorityOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumAdaptivePriorityOverrideAdjuster: AdaptivePriorityOverrideFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptivePriorityOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SourceAdaptivePriorityOverrideAdjuster: AdaptivePriorityOverrideFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: AdaptivePriorityOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the adaptive priority override steps in order and keeps a trace of each.
    final class AdaptivePriorityOverrideEngine {
        var steps: [any AdaptivePriorityOverrideFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptivePriorityOverrideFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptivePriorityOverride) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptivePriorityOverrideFactor = steps[index]
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

        func evaluateAll(_ items: [AdaptivePriorityOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptivePriorityOverrideEngine() -> AdaptivePriorityOverrideEngine {
        return AdaptivePriorityOverrideEngine(
            steps: [
                PercentAdaptivePriorityOverrideAdjuster(percent: 13.5),
                AdaptivePriorityOverrideExpiresAtOffsetAdjuster(weight: 0.89),
                RoundingAdaptivePriorityOverrideAdjuster(step: 5.0),
                MinimumAdaptivePriorityOverrideAdjuster(minimum: 14.4),
                SourceAdaptivePriorityOverrideAdjuster(factors: ["central": 1.25, "north": 0.95, "retail": 0.86]),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 39644.8
        )
    }
}
