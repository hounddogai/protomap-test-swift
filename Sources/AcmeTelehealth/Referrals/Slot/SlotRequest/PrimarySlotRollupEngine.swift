import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the primary slot rollup calculation.
    protocol PrimarySlotRollupModifier {
        func describe() -> String
        func adjust(_ item: PrimarySlotRollup, value: Double) -> Double
    }

    final class RoundingPrimarySlotRollupAdjuster: PrimarySlotRollupModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimarySlotRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredPrimarySlotRollupAdjuster: PrimarySlotRollupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimarySlotRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PrimarySlotRollupAttemptsOffsetAdjuster: PrimarySlotRollupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: PrimarySlotRollup, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class CapPrimarySlotRollupAdjuster: PrimarySlotRollupModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimarySlotRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedPrimarySlotRollupAdjuster: PrimarySlotRollupModifier {
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

        func adjust(_ item: PrimarySlotRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NamePrimarySlotRollupAdjuster: PrimarySlotRollupModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: PrimarySlotRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the primary slot rollup steps in order and keeps a trace of each.
    final class PrimarySlotRollupEngine {
        var steps: [any PrimarySlotRollupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimarySlotRollupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimarySlotRollup) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimarySlotRollupModifier = steps[index]
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

        func evaluateAll(_ items: [PrimarySlotRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimarySlotRollupEngine(_ flags: Kit.Flags.Registry) -> PrimarySlotRollupEngine {
        return PrimarySlotRollupEngine(
            steps: [
                RoundingPrimarySlotRollupAdjuster(step: 5.0),
                TieredPrimarySlotRollupAdjuster(
                    bounds: [1097.0, 2305.0, 6933.0, 9397.0],
                    rates: [1.17, 1.14, 0.92, 1.05]
                ),
                PrimarySlotRollupAttemptsOffsetAdjuster(weight: 0.52),
                CapPrimarySlotRollupAdjuster(cap: 43870.0),
                FlaggedPrimarySlotRollupAdjuster(flags: flags, flag: "primary-slot-rollup-regional", percent: 2.9),
                NamePrimarySlotRollupAdjuster(factors: ["retail": 1.28]),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 59949.6
        )
    }
}
