import AcmePlatform
import Foundation

extension Consent {
    /// One step of the scheduled proxy group calculation.
    protocol ScheduledProxyGroupStep {
        func describe() -> String
        func adjust(_ item: ScheduledProxyGroup, value: Double) -> Double
    }

    final class LabelScheduledProxyGroupAdjuster: ScheduledProxyGroupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ScheduledProxyGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingScheduledProxyGroupAdjuster: ScheduledProxyGroupStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledProxyGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapScheduledProxyGroupAdjuster: ScheduledProxyGroupStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledProxyGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ScheduledProxyGroupBatchSizeOffsetAdjuster: ScheduledProxyGroupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: ScheduledProxyGroup, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class FlaggedScheduledProxyGroupAdjuster: ScheduledProxyGroupStep {
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

        func adjust(_ item: ScheduledProxyGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled proxy group steps in order and keeps a trace of each.
    final class ScheduledProxyGroupEngine {
        var steps: [any ScheduledProxyGroupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledProxyGroupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledProxyGroup) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [ScheduledProxyGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledProxyGroupEngine(_ flags: Kit.Flags.Registry) -> ScheduledProxyGroupEngine {
        return ScheduledProxyGroupEngine(
            steps: [
                LabelScheduledProxyGroupAdjuster(factors: ["north": 1.27, "central": 0.81]),
                RoundingScheduledProxyGroupAdjuster(step: 5.0),
                CapScheduledProxyGroupAdjuster(cap: 10929.0),
                ScheduledProxyGroupBatchSizeOffsetAdjuster(weight: 0.66),
                FlaggedScheduledProxyGroupAdjuster(
                    flags: flags,
                    flag: "scheduled-proxy-group-regional",
                    percent: -5.0
                ),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 33350.1
        )
    }
}
