import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the adaptive rounding draft calculation.
    protocol AdaptiveRoundingDraftStep {
        func describe() -> String
        func adjust(_ item: AdaptiveRoundingDraft, value: Double) -> Double
    }

    final class RoundingAdaptiveRoundingDraftAdjuster: AdaptiveRoundingDraftStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveRoundingDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumAdaptiveRoundingDraftAdjuster: AdaptiveRoundingDraftStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveRoundingDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelAdaptiveRoundingDraftAdjuster: AdaptiveRoundingDraftStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: AdaptiveRoundingDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredAdaptiveRoundingDraftAdjuster: AdaptiveRoundingDraftStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveRoundingDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the adaptive rounding draft steps in order and keeps a trace of each.
    final class AdaptiveRoundingDraftEngine {
        var steps: [any AdaptiveRoundingDraftStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveRoundingDraftStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveRoundingDraft) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveRoundingDraftStep = steps[index]
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

        func evaluateAll(_ items: [AdaptiveRoundingDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveRoundingDraftEngine() -> AdaptiveRoundingDraftEngine {
        return AdaptiveRoundingDraftEngine(
            steps: [
                RoundingAdaptiveRoundingDraftAdjuster(step: 5.0),
                MinimumAdaptiveRoundingDraftAdjuster(minimum: 7.5),
                LabelAdaptiveRoundingDraftAdjuster(factors: ["north": 1.38, "east": 1.2]),
                TieredAdaptiveRoundingDraftAdjuster(bounds: [4671.0, 7418.0, 7696.0], rates: [1.14, 0.96, 1.13]),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 57556.2
        )
    }
}
