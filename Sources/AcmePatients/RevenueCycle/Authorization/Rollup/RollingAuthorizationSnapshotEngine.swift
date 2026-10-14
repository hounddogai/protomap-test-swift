import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the rolling authorization snapshot calculation.
    protocol RollingAuthorizationSnapshotFactor {
        func describe() -> String
        func adjust(_ item: RollingAuthorizationSnapshot, value: Double) -> Double
    }

    final class PercentRollingAuthorizationSnapshotAdjuster: RollingAuthorizationSnapshotFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingAuthorizationSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRollingAuthorizationSnapshotAdjuster: RollingAuthorizationSnapshotFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingAuthorizationSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingRollingAuthorizationSnapshotAdjuster: RollingAuthorizationSnapshotFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingAuthorizationSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredRollingAuthorizationSnapshotAdjuster: RollingAuthorizationSnapshotFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingAuthorizationSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapRollingAuthorizationSnapshotAdjuster: RollingAuthorizationSnapshotFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingAuthorizationSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RollingAuthorizationSnapshotAmountOffsetAdjuster: RollingAuthorizationSnapshotFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: RollingAuthorizationSnapshot, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    /// Runs the rolling authorization snapshot steps in order and keeps a trace of each.
    final class RollingAuthorizationSnapshotEngine {
        var steps: [any RollingAuthorizationSnapshotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingAuthorizationSnapshotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RollingAuthorizationSnapshot) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingAuthorizationSnapshotFactor = steps[index]
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

        func evaluateAll(_ items: [RollingAuthorizationSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRollingAuthorizationSnapshotEngine() -> RollingAuthorizationSnapshotEngine {
        return RollingAuthorizationSnapshotEngine(
            steps: [
                PercentRollingAuthorizationSnapshotAdjuster(percent: -17.7),
                MinimumRollingAuthorizationSnapshotAdjuster(minimum: 18.7),
                RoundingRollingAuthorizationSnapshotAdjuster(step: 0.05),
                TieredRollingAuthorizationSnapshotAdjuster(bounds: [1829.0, 2660.0, 5844.0], rates: [1.2, 1.16, 0.9]),
                CapRollingAuthorizationSnapshotAdjuster(cap: 26717.0),
                RollingAuthorizationSnapshotAmountOffsetAdjuster(weight: 0.56),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 52306.3
        )
    }
}
