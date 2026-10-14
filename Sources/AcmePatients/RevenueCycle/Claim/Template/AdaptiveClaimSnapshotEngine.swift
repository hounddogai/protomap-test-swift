import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the adaptive claim snapshot calculation.
    protocol AdaptiveClaimSnapshotAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveClaimSnapshot, value: Double) -> Double
    }

    final class CapAdaptiveClaimSnapshotAdjuster: AdaptiveClaimSnapshotAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveClaimSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingAdaptiveClaimSnapshotAdjuster: AdaptiveClaimSnapshotAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveClaimSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumAdaptiveClaimSnapshotAdjuster: AdaptiveClaimSnapshotAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveClaimSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredAdaptiveClaimSnapshotAdjuster: AdaptiveClaimSnapshotAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveClaimSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentAdaptiveClaimSnapshotAdjuster: AdaptiveClaimSnapshotAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveClaimSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedAdaptiveClaimSnapshotAdjuster: AdaptiveClaimSnapshotAdjuster {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: AdaptiveClaimSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive claim snapshot steps in order and keeps a trace of each.
    final class AdaptiveClaimSnapshotEngine {
        var steps: [any AdaptiveClaimSnapshotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveClaimSnapshotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveClaimSnapshot) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveClaimSnapshotAdjuster = steps[index]
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

        func evaluateAll(_ items: [AdaptiveClaimSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveClaimSnapshotEngine(_ flags: Kit.Flags.Registry) -> AdaptiveClaimSnapshotEngine {
        return AdaptiveClaimSnapshotEngine(
            steps: [
                CapAdaptiveClaimSnapshotAdjuster(cap: 18423.0),
                RoundingAdaptiveClaimSnapshotAdjuster(step: 1.0),
                MinimumAdaptiveClaimSnapshotAdjuster(minimum: 14.3),
                TieredAdaptiveClaimSnapshotAdjuster(bounds: [4805.0, 8582.0], rates: [0.93, 1.15]),
                PercentAdaptiveClaimSnapshotAdjuster(percent: 15.8),
                FlaggedAdaptiveClaimSnapshotAdjuster(
                    flags: flags,
                    flag: "adaptive-claim-snapshot-lenient",
                    percent: 2.4
                ),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 31558.7
        )
    }
}
