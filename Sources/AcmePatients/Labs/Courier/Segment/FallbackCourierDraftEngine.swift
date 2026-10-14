import AcmePlatform
import Foundation

extension Labs {
    /// One step of the fallback courier draft calculation.
    protocol FallbackCourierDraftStep {
        func describe() -> String
        func adjust(_ item: FallbackCourierDraft, value: Double) -> Double
    }

    final class FallbackCourierDraftSequenceOffsetAdjuster: FallbackCourierDraftStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: FallbackCourierDraft, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class RoundingFallbackCourierDraftAdjuster: FallbackCourierDraftStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackCourierDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumFallbackCourierDraftAdjuster: FallbackCourierDraftStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackCourierDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RegionFallbackCourierDraftAdjuster: FallbackCourierDraftStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: FallbackCourierDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredFallbackCourierDraftAdjuster: FallbackCourierDraftStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackCourierDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the fallback courier draft steps in order and keeps a trace of each.
    final class FallbackCourierDraftEngine {
        var steps: [any FallbackCourierDraftStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackCourierDraftStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackCourierDraft) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackCourierDraftStep = steps[index]
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

        func evaluateAll(_ items: [FallbackCourierDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackCourierDraftEngine() -> FallbackCourierDraftEngine {
        return FallbackCourierDraftEngine(
            steps: [
                FallbackCourierDraftSequenceOffsetAdjuster(weight: 0.9),
                RoundingFallbackCourierDraftAdjuster(step: 0.1),
                MinimumFallbackCourierDraftAdjuster(minimum: 5.4),
                RegionFallbackCourierDraftAdjuster(factors: ["retail": 0.97]),
                TieredFallbackCourierDraftAdjuster(bounds: [5416.0, 9269.0], rates: [1.1, 0.85]),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 17264.6
        )
    }
}
