import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up target calculation.
    protocol FollowUpTargetModifier {
        func describe() -> String
        func adjust(_ item: FollowUpTarget, value: Double) -> Double
    }

    final class TieredFollowUpTargetAdjuster: FollowUpTargetModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FollowUpTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentFollowUpTargetAdjuster: FollowUpTargetModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FollowUpTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFollowUpTargetAdjuster: FollowUpTargetModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FollowUpTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapFollowUpTargetAdjuster: FollowUpTargetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FollowUpTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FollowUpTargetMaximumOffsetAdjuster: FollowUpTargetModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: FollowUpTarget, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    /// Runs the follow up target steps in order and keeps a trace of each.
    final class FollowUpTargetEngine {
        var steps: [any FollowUpTargetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpTargetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FollowUpTarget) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [FollowUpTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFollowUpTargetEngine() -> FollowUpTargetEngine {
        return FollowUpTargetEngine(
            steps: [
                TieredFollowUpTargetAdjuster(bounds: [451.0, 4696.0, 9085.0, 9824.0], rates: [1.04, 1.19, 0.97, 1.1]),
                PercentFollowUpTargetAdjuster(percent: -22.1),
                RoundingFollowUpTargetAdjuster(step: 0.5),
                CapFollowUpTargetAdjuster(cap: 1889.0),
                FollowUpTargetMaximumOffsetAdjuster(weight: 0.48),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 9096.0
        )
    }
}
