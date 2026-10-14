import AcmePlatform
import Foundation

extension Consent {
    /// One step of the tiered proxy milestone calculation.
    protocol MilestoneTieredProxyMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: TieredProxyMilestone, value: Double) -> Double
    }

    final class MinimumTieredProxyMilestoneAdjuster: MilestoneTieredProxyMilestoneAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredProxyMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedTieredProxyMilestoneAdjuster: MilestoneTieredProxyMilestoneAdjuster {
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

        func adjust(_ item: TieredProxyMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameTieredProxyMilestoneAdjuster: MilestoneTieredProxyMilestoneAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: TieredProxyMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentTieredProxyMilestoneAdjuster: MilestoneTieredProxyMilestoneAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredProxyMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the tiered proxy milestone steps in order and keeps a trace of each.
    final class TieredProxyMilestoneEngine {
        var steps: [any MilestoneTieredProxyMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any MilestoneTieredProxyMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredProxyMilestone) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [TieredProxyMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredProxyMilestoneEngine(_ flags: Kit.Flags.Registry) -> TieredProxyMilestoneEngine {
        return TieredProxyMilestoneEngine(
            steps: [
                MinimumTieredProxyMilestoneAdjuster(minimum: 13.0),
                FlaggedTieredProxyMilestoneAdjuster(
                    flags: flags,
                    flag: "tiered-proxy-milestone-tiered",
                    percent: -3.2
                ),
                NameTieredProxyMilestoneAdjuster(factors: ["online": 1.38, "central": 0.9]),
                PercentTieredProxyMilestoneAdjuster(percent: 21.8),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 72127.6
        )
    }
}
