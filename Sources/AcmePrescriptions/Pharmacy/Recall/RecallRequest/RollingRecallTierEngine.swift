import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the rolling recall tier calculation.
    protocol RollingRecallTierFactor {
        func describe() -> String
        func adjust(_ item: RollingRecallTier, value: Double) -> Double
    }

    final class MinimumRollingRecallTierAdjuster: RollingRecallTierFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingRecallTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentRollingRecallTierAdjuster: RollingRecallTierFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingRecallTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRollingRecallTierAdjuster: RollingRecallTierFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingRecallTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the rolling recall tier steps in order and keeps a trace of each.
    final class RollingRecallTierEngine {
        var steps: [any RollingRecallTierFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingRecallTierFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingRecallTier) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [RollingRecallTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingRecallTierEngine() -> RollingRecallTierEngine {
        return RollingRecallTierEngine(
            steps: [
                MinimumRollingRecallTierAdjuster(minimum: 9.8),
                PercentRollingRecallTierAdjuster(percent: -8.1),
                CapRollingRecallTierAdjuster(cap: 37027.0),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 93068.7
        )
    }
}
