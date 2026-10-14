import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim milestone calculation.
    protocol ClaimMilestoneFactor {
        func describe() -> String
        func adjust(_ item: ClaimMilestone, value: Double) -> Double
    }

    final class TieredClaimMilestoneAdjuster: ClaimMilestoneFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClaimMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ClaimMilestoneCapacityOffsetAdjuster: ClaimMilestoneFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: ClaimMilestone, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class FlaggedClaimMilestoneAdjuster: ClaimMilestoneFactor {
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

        func adjust(_ item: ClaimMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumClaimMilestoneAdjuster: ClaimMilestoneFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClaimMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the claim milestone steps in order and keeps a trace of each.
    final class ClaimMilestoneEngine {
        var steps: [any ClaimMilestoneFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimMilestoneFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ClaimMilestone) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [ClaimMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultClaimMilestoneEngine(_ flags: Kit.Flags.Registry) -> ClaimMilestoneEngine {
        return ClaimMilestoneEngine(
            steps: [
                TieredClaimMilestoneAdjuster(bounds: [4403.0, 5044.0], rates: [0.84, 1.02]),
                ClaimMilestoneCapacityOffsetAdjuster(weight: 0.19),
                FlaggedClaimMilestoneAdjuster(flags: flags, flag: "claim-milestone-tiered", percent: 2.7),
                MinimumClaimMilestoneAdjuster(minimum: 12.5),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 88082.0
        )
    }
}
