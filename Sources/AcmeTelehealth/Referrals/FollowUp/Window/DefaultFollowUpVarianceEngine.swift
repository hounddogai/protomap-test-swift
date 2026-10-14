import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the default follow up variance calculation.
    protocol DefaultFollowUpVarianceModifier {
        func describe() -> String
        func adjust(_ item: DefaultFollowUpVariance, value: Double) -> Double
    }

    final class MinimumDefaultFollowUpVarianceAdjuster: DefaultFollowUpVarianceModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultFollowUpVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentDefaultFollowUpVarianceAdjuster: DefaultFollowUpVarianceModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultFollowUpVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDefaultFollowUpVarianceAdjuster: DefaultFollowUpVarianceModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultFollowUpVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the default follow up variance steps in order and keeps a trace of each.
    final class DefaultFollowUpVarianceEngine {
        var steps: [any DefaultFollowUpVarianceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultFollowUpVarianceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultFollowUpVariance) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultFollowUpVarianceModifier = steps[index]
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

        func evaluateAll(_ items: [DefaultFollowUpVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultFollowUpVarianceEngine() -> DefaultFollowUpVarianceEngine {
        return DefaultFollowUpVarianceEngine(
            steps: [
                MinimumDefaultFollowUpVarianceAdjuster(minimum: 35.8),
                PercentDefaultFollowUpVarianceAdjuster(percent: 6.1),
                RoundingDefaultFollowUpVarianceAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 63736.7
        )
    }
}
