import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the fallback formulary review calculation.
    protocol FallbackFormularyReviewStep {
        func describe() -> String
        func adjust(_ item: FallbackFormularyReview, value: Double) -> Double
    }

    final class NameFallbackFormularyReviewAdjuster: FallbackFormularyReviewStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: FallbackFormularyReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapFallbackFormularyReviewAdjuster: FallbackFormularyReviewStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackFormularyReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedFallbackFormularyReviewAdjuster: FallbackFormularyReviewStep {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: FallbackFormularyReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentFallbackFormularyReviewAdjuster: FallbackFormularyReviewStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackFormularyReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback formulary review steps in order and keeps a trace of each.
    final class FallbackFormularyReviewEngine {
        var steps: [any FallbackFormularyReviewStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackFormularyReviewStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackFormularyReview) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [FallbackFormularyReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackFormularyReviewEngine(_ flags: Kit.Flags.Registry) -> FallbackFormularyReviewEngine {
        return FallbackFormularyReviewEngine(
            steps: [
                NameFallbackFormularyReviewAdjuster(factors: ["retail": 0.75]),
                CapFallbackFormularyReviewAdjuster(cap: 24642.0),
                FlaggedFallbackFormularyReviewAdjuster(
                    flags: flags,
                    flag: "fallback-formulary-review-scheduled",
                    percent: 3.1
                ),
                PercentFallbackFormularyReviewAdjuster(percent: 19.2),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 91237.8
        )
    }
}
