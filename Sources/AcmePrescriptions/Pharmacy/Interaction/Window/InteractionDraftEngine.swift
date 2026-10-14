import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the interaction draft calculation.
    protocol InteractionDraftFactor {
        func describe() -> String
        func adjust(_ item: InteractionDraft, value: Double) -> Double
    }

    final class CapInteractionDraftAdjuster: InteractionDraftFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InteractionDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingInteractionDraftAdjuster: InteractionDraftFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InteractionDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredInteractionDraftAdjuster: InteractionDraftFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InteractionDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class InteractionDraftBatchSizeOffsetAdjuster: InteractionDraftFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: InteractionDraft, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class LabelInteractionDraftAdjuster: InteractionDraftFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: InteractionDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumInteractionDraftAdjuster: InteractionDraftFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InteractionDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the interaction draft steps in order and keeps a trace of each.
    final class InteractionDraftEngine {
        var steps: [any InteractionDraftFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InteractionDraftFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: InteractionDraft) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any InteractionDraftFactor = steps[index]
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

        func evaluateAll(_ items: [InteractionDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultInteractionDraftEngine() -> InteractionDraftEngine {
        return InteractionDraftEngine(
            steps: [
                CapInteractionDraftAdjuster(cap: 43885.0),
                RoundingInteractionDraftAdjuster(step: 5.0),
                TieredInteractionDraftAdjuster(bounds: [107.0, 3286.0, 3659.0], rates: [1.04, 1.16, 0.93]),
                InteractionDraftBatchSizeOffsetAdjuster(weight: 1.26),
                LabelInteractionDraftAdjuster(factors: ["north": 1.0]),
                MinimumInteractionDraftAdjuster(minimum: 32.5),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 96592.9
        )
    }
}
