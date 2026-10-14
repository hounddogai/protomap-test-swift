import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the fallback follow up cycle calculation.
    protocol FallbackFollowUpCycleFactor {
        func describe() -> String
        func adjust(_ item: FallbackFollowUpCycle, value: Double) -> Double
    }

    final class CapFallbackFollowUpCycleAdjuster: FallbackFollowUpCycleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackFollowUpCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentFallbackFollowUpCycleAdjuster: FallbackFollowUpCycleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackFollowUpCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionFallbackFollowUpCycleAdjuster: FallbackFollowUpCycleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: FallbackFollowUpCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedFallbackFollowUpCycleAdjuster: FallbackFollowUpCycleFactor {
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

        func adjust(_ item: FallbackFollowUpCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FallbackFollowUpCycleCapacityOffsetAdjuster: FallbackFollowUpCycleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: FallbackFollowUpCycle, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    /// Runs the fallback follow up cycle steps in order and keeps a trace of each.
    final class FallbackFollowUpCycleEngine {
        var steps: [any FallbackFollowUpCycleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackFollowUpCycleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackFollowUpCycle) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [FallbackFollowUpCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackFollowUpCycleEngine(_ flags: Kit.Flags.Registry) -> FallbackFollowUpCycleEngine {
        return FallbackFollowUpCycleEngine(
            steps: [
                CapFallbackFollowUpCycleAdjuster(cap: 49392.0),
                PercentFallbackFollowUpCycleAdjuster(percent: -0.2),
                RegionFallbackFollowUpCycleAdjuster(factors: ["south": 0.96]),
                FlaggedFallbackFollowUpCycleAdjuster(
                    flags: flags,
                    flag: "fallback-follow-up-cycle-manual",
                    percent: -2.0
                ),
                FallbackFollowUpCycleCapacityOffsetAdjuster(weight: 1.85),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 89959.6
        )
    }
}
