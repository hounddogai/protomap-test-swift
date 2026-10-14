import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the tiered network digest calculation.
    protocol RuleTieredNetworkDigestAdjuster {
        func describe() -> String
        func adjust(_ item: TieredNetworkDigest, value: Double) -> Double
    }

    final class RoundingTieredNetworkDigestAdjuster: RuleTieredNetworkDigestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredNetworkDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapTieredNetworkDigestAdjuster: RuleTieredNetworkDigestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredNetworkDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentTieredNetworkDigestAdjuster: RuleTieredNetworkDigestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredNetworkDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredNetworkDigestStartsAtOffsetAdjuster: RuleTieredNetworkDigestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: TieredNetworkDigest, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class ChannelTieredNetworkDigestAdjuster: RuleTieredNetworkDigestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: TieredNetworkDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedTieredNetworkDigestAdjuster: RuleTieredNetworkDigestAdjuster {
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

        func adjust(_ item: TieredNetworkDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the tiered network digest steps in order and keeps a trace of each.
    final class TieredNetworkDigestEngine {
        var steps: [any RuleTieredNetworkDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RuleTieredNetworkDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredNetworkDigest) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RuleTieredNetworkDigestAdjuster = steps[index]
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

        func evaluateAll(_ items: [TieredNetworkDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredNetworkDigestEngine(_ flags: Kit.Flags.Registry) -> TieredNetworkDigestEngine {
        return TieredNetworkDigestEngine(
            steps: [
                RoundingTieredNetworkDigestAdjuster(step: 0.05),
                CapTieredNetworkDigestAdjuster(cap: 39001.0),
                PercentTieredNetworkDigestAdjuster(percent: -12.5),
                TieredNetworkDigestStartsAtOffsetAdjuster(weight: 0.97),
                ChannelTieredNetworkDigestAdjuster(factors: ["central": 1.4]),
                FlaggedTieredNetworkDigestAdjuster(flags: flags, flag: "tiered-network-digest-global", percent: 9.3),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 10221.1
        )
    }
}
