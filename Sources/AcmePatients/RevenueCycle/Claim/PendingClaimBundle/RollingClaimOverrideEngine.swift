import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the rolling claim override calculation.
    protocol RollingClaimOverrideStep {
        func describe() -> String
        func adjust(_ item: RollingClaimOverride, value: Double) -> Double
    }

    final class MinimumRollingClaimOverrideAdjuster: RollingClaimOverrideStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingClaimOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RollingClaimOverrideScoreOffsetAdjuster: RollingClaimOverrideStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: RollingClaimOverride, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class CapRollingClaimOverrideAdjuster: RollingClaimOverrideStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingClaimOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentRollingClaimOverrideAdjuster: RollingClaimOverrideStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingClaimOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rolling claim override steps in order and keeps a trace of each.
    final class RollingClaimOverrideEngine {
        var steps: [any RollingClaimOverrideStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingClaimOverrideStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingClaimOverride) -> Double {
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

        func evaluateAll(_ items: [RollingClaimOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingClaimOverrideEngine() -> RollingClaimOverrideEngine {
        return RollingClaimOverrideEngine(
            steps: [
                MinimumRollingClaimOverrideAdjuster(minimum: 38.5),
                RollingClaimOverrideScoreOffsetAdjuster(weight: 0.06),
                CapRollingClaimOverrideAdjuster(cap: 21958.0),
                PercentRollingClaimOverrideAdjuster(percent: -13.9),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 88270.7
        )
    }
}
