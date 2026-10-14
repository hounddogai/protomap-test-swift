import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the manual authorization snapshot calculation.
    protocol ManualAuthorizationSnapshotAdjuster {
        func describe() -> String
        func adjust(_ item: ManualAuthorizationSnapshot, value: Double) -> Double
    }

    final class TieredManualAuthorizationSnapshotAdjuster: ManualAuthorizationSnapshotAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualAuthorizationSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapManualAuthorizationSnapshotAdjuster: ManualAuthorizationSnapshotAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualAuthorizationSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingManualAuthorizationSnapshotAdjuster: ManualAuthorizationSnapshotAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualAuthorizationSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumManualAuthorizationSnapshotAdjuster: ManualAuthorizationSnapshotAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualAuthorizationSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentManualAuthorizationSnapshotAdjuster: ManualAuthorizationSnapshotAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualAuthorizationSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual authorization snapshot steps in order and keeps a trace of each.
    final class ManualAuthorizationSnapshotEngine {
        var steps: [any ManualAuthorizationSnapshotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualAuthorizationSnapshotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualAuthorizationSnapshot) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualAuthorizationSnapshotAdjuster = steps[index]
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

        func evaluateAll(_ items: [ManualAuthorizationSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualAuthorizationSnapshotEngine() -> ManualAuthorizationSnapshotEngine {
        return ManualAuthorizationSnapshotEngine(
            steps: [
                TieredManualAuthorizationSnapshotAdjuster(bounds: [3742.0, 8319.0, 8691.0], rates: [1.03, 0.95, 0.93]),
                CapManualAuthorizationSnapshotAdjuster(cap: 42027.0),
                RoundingManualAuthorizationSnapshotAdjuster(step: 5.0),
                MinimumManualAuthorizationSnapshotAdjuster(minimum: 15.8),
                PercentManualAuthorizationSnapshotAdjuster(percent: -12.2),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 20026.8
        )
    }
}
