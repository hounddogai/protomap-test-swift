import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the capped charge tier calculation.
    protocol CappedChargeTierStep {
        func describe() -> String
        func adjust(_ item: CappedChargeTier, value: Double) -> Double
    }

    final class PercentCappedChargeTierAdjuster: CappedChargeTierStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedChargeTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedCappedChargeTierAdjuster: CappedChargeTierStep {
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

        func adjust(_ item: CappedChargeTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CappedChargeTierGraceDaysOffsetAdjuster: CappedChargeTierStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: CappedChargeTier, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class CapCappedChargeTierAdjuster: CappedChargeTierStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedChargeTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class UnitCappedChargeTierAdjuster: CappedChargeTierStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: CappedChargeTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCappedChargeTierAdjuster: CappedChargeTierStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedChargeTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the capped charge tier steps in order and keeps a trace of each.
    final class CappedChargeTierEngine {
        var steps: [any CappedChargeTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedChargeTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedChargeTier) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [CappedChargeTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedChargeTierEngine(_ flags: Kit.Flags.Registry) -> CappedChargeTierEngine {
        return CappedChargeTierEngine(
            steps: [
                PercentCappedChargeTierAdjuster(percent: -5.7),
                FlaggedCappedChargeTierAdjuster(flags: flags, flag: "capped-charge-tier-weighted", percent: 6.1),
                CappedChargeTierGraceDaysOffsetAdjuster(weight: 0.96),
                CapCappedChargeTierAdjuster(cap: 21168.0),
                UnitCappedChargeTierAdjuster(factors: ["central": 0.77, "north": 1.22]),
                RoundingCappedChargeTierAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 50619.2
        )
    }
}
