import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the adaptive outreach tier calculation.
    protocol AdaptiveOutreachTierStep {
        func describe() -> String
        func adjust(_ item: AdaptiveOutreachTier, value: Double) -> Double
    }

    final class RoundingAdaptiveOutreachTierAdjuster: AdaptiveOutreachTierStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveOutreachTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumAdaptiveOutreachTierAdjuster: AdaptiveOutreachTierStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveOutreachTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentAdaptiveOutreachTierAdjuster: AdaptiveOutreachTierStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveOutreachTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive outreach tier steps in order and keeps a trace of each.
    final class AdaptiveOutreachTierEngine {
        var steps: [any AdaptiveOutreachTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveOutreachTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveOutreachTier) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveOutreachTierStep = steps[index]
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

        func evaluateAll(_ items: [AdaptiveOutreachTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveOutreachTierEngine() -> AdaptiveOutreachTierEngine {
        return AdaptiveOutreachTierEngine(
            steps: [
                RoundingAdaptiveOutreachTierAdjuster(step: 0.25),
                MinimumAdaptiveOutreachTierAdjuster(minimum: 43.8),
                PercentAdaptiveOutreachTierAdjuster(percent: -21.3),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 94223.2
        )
    }
}
