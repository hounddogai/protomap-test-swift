import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial checkpoint calculation.
    protocol DenialCheckpointAdjuster {
        func describe() -> String
        func adjust(_ item: DenialCheckpoint, value: Double) -> Double
    }

    final class CapDenialCheckpointAdjuster: DenialCheckpointAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DenialCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LocaleDenialCheckpointAdjuster: DenialCheckpointAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: DenialCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingDenialCheckpointAdjuster: DenialCheckpointAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DenialCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedDenialCheckpointAdjuster: DenialCheckpointAdjuster {
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

        func adjust(_ item: DenialCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDenialCheckpointAdjuster: DenialCheckpointAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DenialCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumDenialCheckpointAdjuster: DenialCheckpointAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DenialCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the denial checkpoint steps in order and keeps a trace of each.
    final class DenialCheckpointEngine {
        var steps: [any DenialCheckpointAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialCheckpointAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DenialCheckpoint) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any DenialCheckpointAdjuster = steps[index]
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

        func evaluateAll(_ items: [DenialCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDenialCheckpointEngine(_ flags: Kit.Flags.Registry) -> DenialCheckpointEngine {
        return DenialCheckpointEngine(
            steps: [
                CapDenialCheckpointAdjuster(cap: 10295.0),
                LocaleDenialCheckpointAdjuster(factors: ["retail": 1.16, "south": 0.83, "north": 1.34]),
                RoundingDenialCheckpointAdjuster(step: 0.1),
                FlaggedDenialCheckpointAdjuster(flags: flags, flag: "denial-checkpoint-adaptive", percent: -7.3),
                TieredDenialCheckpointAdjuster(bounds: [1150.0, 3906.0], rates: [0.92, 1.15]),
                MinimumDenialCheckpointAdjuster(minimum: 49.4),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 73939.4
        )
    }
}
