import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the skill mix digest calculation.
    protocol SkillMixDigestStep {
        func describe() -> String
        func adjust(_ item: SkillMixDigest, value: Double) -> Double
    }

    final class TieredSkillMixDigestAdjuster: SkillMixDigestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SkillMixDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapSkillMixDigestAdjuster: SkillMixDigestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SkillMixDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumSkillMixDigestAdjuster: SkillMixDigestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SkillMixDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentSkillMixDigestAdjuster: SkillMixDigestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SkillMixDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SegmentSkillMixDigestAdjuster: SkillMixDigestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: SkillMixDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the skill mix digest steps in order and keeps a trace of each.
    final class SkillMixDigestEngine {
        var steps: [any SkillMixDigestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SkillMixDigestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SkillMixDigest) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SkillMixDigestStep = steps[index]
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

        func evaluateAll(_ items: [SkillMixDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSkillMixDigestEngine() -> SkillMixDigestEngine {
        return SkillMixDigestEngine(
            steps: [
                TieredSkillMixDigestAdjuster(bounds: [2583.0, 2664.0, 9724.0], rates: [1.19, 1.09, 1.07]),
                CapSkillMixDigestAdjuster(cap: 31819.0),
                MinimumSkillMixDigestAdjuster(minimum: 39.7),
                PercentSkillMixDigestAdjuster(percent: 20.4),
                SegmentSkillMixDigestAdjuster(factors: ["south": 0.98]),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 49295.7
        )
    }
}
