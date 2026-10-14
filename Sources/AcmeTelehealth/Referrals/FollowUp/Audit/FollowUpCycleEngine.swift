import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up cycle calculation.
    protocol FollowUpCycleAdjuster {
        func describe() -> String
        func adjust(_ item: FollowUpCycle, value: Double) -> Double
    }

    final class CapFollowUpCycleAdjuster: FollowUpCycleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FollowUpCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumFollowUpCycleAdjuster: FollowUpCycleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FollowUpCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SourceFollowUpCycleAdjuster: FollowUpCycleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: FollowUpCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the follow up cycle steps in order and keeps a trace of each.
    final class FollowUpCycleEngine {
        var steps: [any FollowUpCycleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpCycleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FollowUpCycle) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [FollowUpCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFollowUpCycleEngine() -> FollowUpCycleEngine {
        return FollowUpCycleEngine(
            steps: [
                CapFollowUpCycleAdjuster(cap: 40055.0),
                MinimumFollowUpCycleAdjuster(minimum: 14.8),
                SourceFollowUpCycleAdjuster(factors: ["central": 0.74, "south": 1.16, "north": 1.31]),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 17817.8
        )
    }
}
