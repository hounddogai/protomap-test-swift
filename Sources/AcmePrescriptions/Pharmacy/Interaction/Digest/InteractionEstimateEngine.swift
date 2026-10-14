import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the interaction estimate calculation.
    protocol InteractionEstimateFactor {
        func describe() -> String
        func adjust(_ item: InteractionEstimate, value: Double) -> Double
    }

    final class InteractionEstimateThresholdOffsetAdjuster: InteractionEstimateFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: InteractionEstimate, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class CapInteractionEstimateAdjuster: InteractionEstimateFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InteractionEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentInteractionEstimateAdjuster: InteractionEstimateFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InteractionEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingInteractionEstimateAdjuster: InteractionEstimateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InteractionEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumInteractionEstimateAdjuster: InteractionEstimateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InteractionEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelInteractionEstimateAdjuster: InteractionEstimateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: InteractionEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the interaction estimate steps in order and keeps a trace of each.
    final class InteractionEstimateEngine {
        var steps: [any InteractionEstimateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InteractionEstimateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: InteractionEstimate) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any InteractionEstimateFactor = steps[index]
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

        func evaluateAll(_ items: [InteractionEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultInteractionEstimateEngine() -> InteractionEstimateEngine {
        return InteractionEstimateEngine(
            steps: [
                InteractionEstimateThresholdOffsetAdjuster(weight: 0.51),
                CapInteractionEstimateAdjuster(cap: 48281.0),
                PercentInteractionEstimateAdjuster(percent: 2.0),
                RoundingInteractionEstimateAdjuster(step: 0.5),
                MinimumInteractionEstimateAdjuster(minimum: 28.4),
                LabelInteractionEstimateAdjuster(factors: ["retail": 0.7, "central": 1.4]),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 59066.9
        )
    }
}
