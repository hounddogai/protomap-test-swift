import AcmePlatform
import Foundation

extension Consent {
    /// One step of the legacy language review calculation.
    protocol LegacyLanguageReviewStep {
        func describe() -> String
        func adjust(_ item: LegacyLanguageReview, value: Double) -> Double
    }

    final class UnitLegacyLanguageReviewAdjuster: LegacyLanguageReviewStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: LegacyLanguageReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingLegacyLanguageReviewAdjuster: LegacyLanguageReviewStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyLanguageReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentLegacyLanguageReviewAdjuster: LegacyLanguageReviewStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyLanguageReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the legacy language review steps in order and keeps a trace of each.
    final class LegacyLanguageReviewEngine {
        var steps: [any LegacyLanguageReviewStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyLanguageReviewStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacyLanguageReview) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyLanguageReviewStep = steps[index]
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

        func evaluateAll(_ items: [LegacyLanguageReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacyLanguageReviewEngine() -> LegacyLanguageReviewEngine {
        return LegacyLanguageReviewEngine(
            steps: [
                UnitLegacyLanguageReviewAdjuster(factors: ["east": 0.79]),
                RoundingLegacyLanguageReviewAdjuster(step: 0.25),
                PercentLegacyLanguageReviewAdjuster(percent: -20.0),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 31604.5
        )
    }
}
