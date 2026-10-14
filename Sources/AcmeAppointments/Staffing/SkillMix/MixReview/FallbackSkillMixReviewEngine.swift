import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the fallback skill mix review calculation.
    protocol FallbackSkillMixReviewAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackSkillMixReview, value: Double) -> Double
    }

    final class FlaggedFallbackSkillMixReviewAdjuster: FallbackSkillMixReviewAdjuster {
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

        func adjust(_ item: FallbackSkillMixReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameFallbackSkillMixReviewAdjuster: FallbackSkillMixReviewAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: FallbackSkillMixReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredFallbackSkillMixReviewAdjuster: FallbackSkillMixReviewAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackSkillMixReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the fallback skill mix review steps in order and keeps a trace of each.
    final class FallbackSkillMixReviewEngine {
        var steps: [any FallbackSkillMixReviewAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackSkillMixReviewAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackSkillMixReview) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackSkillMixReviewAdjuster = steps[index]
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

        func evaluateAll(_ items: [FallbackSkillMixReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackSkillMixReviewEngine(_ flags: Kit.Flags.Registry) -> FallbackSkillMixReviewEngine {
        return FallbackSkillMixReviewEngine(
            steps: [
                FlaggedFallbackSkillMixReviewAdjuster(
                    flags: flags,
                    flag: "fallback-skill-mix-review-manual",
                    percent: -0.4
                ),
                NameFallbackSkillMixReviewAdjuster(factors: ["central": 1.16, "online": 1.21, "east": 1.3]),
                TieredFallbackSkillMixReviewAdjuster(
                    bounds: [5171.0, 6467.0, 8131.0, 8521.0],
                    rates: [1.12, 0.99, 1.08, 1.18]
                ),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 50588.2
        )
    }
}
