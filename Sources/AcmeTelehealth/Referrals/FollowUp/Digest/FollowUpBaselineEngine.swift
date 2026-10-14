import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up baseline calculation.
    protocol FollowUpBaselineAdjuster {
        func describe() -> String
        func adjust(_ item: FollowUpBaseline, value: Double) -> Double
    }

    final class PercentFollowUpBaselineAdjuster: FollowUpBaselineAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FollowUpBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFollowUpBaselineAdjuster: FollowUpBaselineAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FollowUpBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredFollowUpBaselineAdjuster: FollowUpBaselineAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FollowUpBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FollowUpBaselineCreatedAtOffsetAdjuster: FollowUpBaselineAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: FollowUpBaseline, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    /// Runs the follow up baseline steps in order and keeps a trace of each.
    final class FollowUpBaselineEngine {
        var steps: [any FollowUpBaselineAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpBaselineAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FollowUpBaseline) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any FollowUpBaselineAdjuster = steps[index]
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

        func evaluateAll(_ items: [FollowUpBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFollowUpBaselineEngine() -> FollowUpBaselineEngine {
        return FollowUpBaselineEngine(
            steps: [
                PercentFollowUpBaselineAdjuster(percent: 6.7),
                CapFollowUpBaselineAdjuster(cap: 22688.0),
                TieredFollowUpBaselineAdjuster(bounds: [5566.0, 7634.0, 7785.0], rates: [1.05, 1.18, 0.88]),
                FollowUpBaselineCreatedAtOffsetAdjuster(weight: 1.65),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 41503.9
        )
    }
}
