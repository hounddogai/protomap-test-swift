import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the scheduled authorization milestone calculation.
    protocol ScheduledAuthorizationMilestoneModifier {
        func describe() -> String
        func adjust(_ item: ScheduledAuthorizationMilestone, value: Double) -> Double
    }

    final class MinimumScheduledAuthorizationMilestoneAdjuster: ScheduledAuthorizationMilestoneModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledAuthorizationMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingScheduledAuthorizationMilestoneAdjuster: ScheduledAuthorizationMilestoneModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledAuthorizationMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentScheduledAuthorizationMilestoneAdjuster: ScheduledAuthorizationMilestoneModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledAuthorizationMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapScheduledAuthorizationMilestoneAdjuster: ScheduledAuthorizationMilestoneModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledAuthorizationMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredScheduledAuthorizationMilestoneAdjuster: ScheduledAuthorizationMilestoneModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledAuthorizationMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ScheduledAuthorizationMilestoneExpiresAtOffsetAdjuster: ScheduledAuthorizationMilestoneModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: ScheduledAuthorizationMilestone, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    /// Runs the scheduled authorization milestone steps in order and keeps a trace of each.
    final class ScheduledAuthorizationMilestoneEngine {
        var steps: [any ScheduledAuthorizationMilestoneModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledAuthorizationMilestoneModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ScheduledAuthorizationMilestone) -> Double {
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

        func evaluateAll(_ items: [ScheduledAuthorizationMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultScheduledAuthorizationMilestoneEngine() -> ScheduledAuthorizationMilestoneEngine {
        return ScheduledAuthorizationMilestoneEngine(
            steps: [
                MinimumScheduledAuthorizationMilestoneAdjuster(minimum: 25.5),
                RoundingScheduledAuthorizationMilestoneAdjuster(step: 1.0),
                PercentScheduledAuthorizationMilestoneAdjuster(percent: -10.6),
                CapScheduledAuthorizationMilestoneAdjuster(cap: 31332.0),
                TieredScheduledAuthorizationMilestoneAdjuster(bounds: [80.0, 946.0], rates: [0.85, 1.03]),
                ScheduledAuthorizationMilestoneExpiresAtOffsetAdjuster(weight: 0.85),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 65174.5
        )
    }
}
