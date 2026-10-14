import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the pending slot target calculation.
    protocol PendingSlotTargetAdjuster {
        func describe() -> String
        func adjust(_ item: PendingSlotTarget, value: Double) -> Double
    }

    final class FlaggedPendingSlotTargetAdjuster: PendingSlotTargetAdjuster {
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

        func adjust(_ item: PendingSlotTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPendingSlotTargetAdjuster: PendingSlotTargetAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingSlotTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NamePendingSlotTargetAdjuster: PendingSlotTargetAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: PendingSlotTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumPendingSlotTargetAdjuster: PendingSlotTargetAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingSlotTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the pending slot target steps in order and keeps a trace of each.
    final class PendingSlotTargetEngine {
        var steps: [any PendingSlotTargetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingSlotTargetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingSlotTarget) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [PendingSlotTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingSlotTargetEngine(_ flags: Kit.Flags.Registry) -> PendingSlotTargetEngine {
        return PendingSlotTargetEngine(
            steps: [
                FlaggedPendingSlotTargetAdjuster(flags: flags, flag: "pending-slot-target-weighted", percent: -7.4),
                TieredPendingSlotTargetAdjuster(bounds: [3918.0, 4602.0], rates: [0.82, 1.04]),
                NamePendingSlotTargetAdjuster(factors: ["central": 1.04, "retail": 0.83]),
                MinimumPendingSlotTargetAdjuster(minimum: 29.6),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 63637.6
        )
    }
}
