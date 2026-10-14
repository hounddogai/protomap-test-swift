import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the tiered claim checkpoint calculation.
    protocol TieredClaimCheckpointAdjuster {
        func describe() -> String
        func adjust(_ item: TieredClaimCheckpoint, value: Double) -> Double
    }

    final class PercentTieredClaimCheckpointAdjuster: TieredClaimCheckpointAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredClaimCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapTieredClaimCheckpointAdjuster: TieredClaimCheckpointAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredClaimCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedTieredClaimCheckpointAdjuster: TieredClaimCheckpointAdjuster {
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

        func adjust(_ item: TieredClaimCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingTieredClaimCheckpointAdjuster: TieredClaimCheckpointAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredClaimCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumTieredClaimCheckpointAdjuster: TieredClaimCheckpointAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredClaimCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SourceTieredClaimCheckpointAdjuster: TieredClaimCheckpointAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: TieredClaimCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the tiered claim checkpoint steps in order and keeps a trace of each.
    final class TieredClaimCheckpointEngine {
        var steps: [any TieredClaimCheckpointAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredClaimCheckpointAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TieredClaimCheckpoint) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredClaimCheckpointAdjuster = steps[index]
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

        func evaluateAll(_ items: [TieredClaimCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTieredClaimCheckpointEngine(_ flags: Kit.Flags.Registry) -> TieredClaimCheckpointEngine {
        return TieredClaimCheckpointEngine(
            steps: [
                PercentTieredClaimCheckpointAdjuster(percent: -7.9),
                CapTieredClaimCheckpointAdjuster(cap: 30623.0),
                FlaggedTieredClaimCheckpointAdjuster(
                    flags: flags,
                    flag: "tiered-claim-checkpoint-legacy",
                    percent: 9.7
                ),
                RoundingTieredClaimCheckpointAdjuster(step: 0.1),
                MinimumTieredClaimCheckpointAdjuster(minimum: 49.8),
                SourceTieredClaimCheckpointAdjuster(factors: ["south": 1.22, "retail": 0.82]),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 58384.6
        )
    }
}
