import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the lenient authorization milestone calculation.
    protocol LenientAuthorizationMilestoneFactor {
        func describe() -> String
        func adjust(_ item: LenientAuthorizationMilestone, value: Double) -> Double
    }

    final class LenientAuthorizationMilestoneMinimumOffsetAdjuster: LenientAuthorizationMilestoneFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: LenientAuthorizationMilestone, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class PercentLenientAuthorizationMilestoneAdjuster: LenientAuthorizationMilestoneFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientAuthorizationMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLenientAuthorizationMilestoneAdjuster: LenientAuthorizationMilestoneFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientAuthorizationMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapLenientAuthorizationMilestoneAdjuster: LenientAuthorizationMilestoneFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientAuthorizationMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the lenient authorization milestone steps in order and keeps a trace of each.
    final class LenientAuthorizationMilestoneEngine {
        var steps: [any LenientAuthorizationMilestoneFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientAuthorizationMilestoneFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientAuthorizationMilestone) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [LenientAuthorizationMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientAuthorizationMilestoneEngine() -> LenientAuthorizationMilestoneEngine {
        return LenientAuthorizationMilestoneEngine(
            steps: [
                LenientAuthorizationMilestoneMinimumOffsetAdjuster(weight: 1.12),
                PercentLenientAuthorizationMilestoneAdjuster(percent: -11.4),
                MinimumLenientAuthorizationMilestoneAdjuster(minimum: 17.2),
                CapLenientAuthorizationMilestoneAdjuster(cap: 26696.0),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 48024.3
        )
    }
}
