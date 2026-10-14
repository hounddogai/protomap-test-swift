import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up segment calculation.
    protocol FollowUpSegmentStep {
        func describe() -> String
        func adjust(_ item: FollowUpSegment, value: Double) -> Double
    }

    final class FollowUpSegmentRatioOffsetAdjuster: FollowUpSegmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: FollowUpSegment, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class TieredFollowUpSegmentAdjuster: FollowUpSegmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FollowUpSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FacilityFollowUpSegmentAdjuster: FollowUpSegmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: FollowUpSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingFollowUpSegmentAdjuster: FollowUpSegmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FollowUpSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapFollowUpSegmentAdjuster: FollowUpSegmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FollowUpSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentFollowUpSegmentAdjuster: FollowUpSegmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FollowUpSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the follow up segment steps in order and keeps a trace of each.
    final class FollowUpSegmentEngine {
        var steps: [any FollowUpSegmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpSegmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FollowUpSegment) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any FollowUpSegmentStep = steps[index]
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

        func evaluateAll(_ items: [FollowUpSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFollowUpSegmentEngine() -> FollowUpSegmentEngine {
        return FollowUpSegmentEngine(
            steps: [
                FollowUpSegmentRatioOffsetAdjuster(weight: 1.64),
                TieredFollowUpSegmentAdjuster(bounds: [1089.0, 5785.0, 6568.0], rates: [1.07, 1.03, 1.2]),
                FacilityFollowUpSegmentAdjuster(factors: ["south": 1.2, "retail": 0.94]),
                RoundingFollowUpSegmentAdjuster(step: 0.05),
                CapFollowUpSegmentAdjuster(cap: 22498.0),
                PercentFollowUpSegmentAdjuster(percent: -21.5),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 85710.1
        )
    }
}
