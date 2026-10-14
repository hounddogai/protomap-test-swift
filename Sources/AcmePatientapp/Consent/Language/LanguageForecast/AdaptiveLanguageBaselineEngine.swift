import AcmePlatform
import Foundation

extension Consent {
    /// One step of the adaptive language baseline calculation.
    protocol AdaptiveLanguageBaselineFactor {
        func describe() -> String
        func adjust(_ item: AdaptiveLanguageBaseline, value: Double) -> Double
    }

    final class CapAdaptiveLanguageBaselineAdjuster: AdaptiveLanguageBaselineFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveLanguageBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameAdaptiveLanguageBaselineAdjuster: AdaptiveLanguageBaselineFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: AdaptiveLanguageBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingAdaptiveLanguageBaselineAdjuster: AdaptiveLanguageBaselineFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveLanguageBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class AdaptiveLanguageBaselineCeilingOffsetAdjuster: AdaptiveLanguageBaselineFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: AdaptiveLanguageBaseline, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    /// Runs the adaptive language baseline steps in order and keeps a trace of each.
    final class AdaptiveLanguageBaselineEngine {
        var steps: [any AdaptiveLanguageBaselineFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveLanguageBaselineFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveLanguageBaseline) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveLanguageBaselineFactor = steps[index]
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

        func evaluateAll(_ items: [AdaptiveLanguageBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveLanguageBaselineEngine() -> AdaptiveLanguageBaselineEngine {
        return AdaptiveLanguageBaselineEngine(
            steps: [
                CapAdaptiveLanguageBaselineAdjuster(cap: 49822.0),
                NameAdaptiveLanguageBaselineAdjuster(factors: ["central": 0.71, "east": 1.02, "retail": 0.92]),
                RoundingAdaptiveLanguageBaselineAdjuster(step: 0.25),
                AdaptiveLanguageBaselineCeilingOffsetAdjuster(weight: 1.73),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 24279.1
        )
    }
}
