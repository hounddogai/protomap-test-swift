import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge tier calculation.
    protocol ChargeTierStep {
        func describe() -> String
        func adjust(_ item: ChargeTier, value: Double) -> Double
    }

    final class CapChargeTierAdjuster: ChargeTierStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ChargeTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ChargeTierAcuityOffsetAdjuster: ChargeTierStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: ChargeTier, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class TieredChargeTierAdjuster: ChargeTierStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ChargeTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingChargeTierAdjuster: ChargeTierStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ChargeTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedChargeTierAdjuster: ChargeTierStep {
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

        func adjust(_ item: ChargeTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameChargeTierAdjuster: ChargeTierStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ChargeTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the charge tier steps in order and keeps a trace of each.
    final class ChargeTierEngine {
        var steps: [any ChargeTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ChargeTier) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [ChargeTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultChargeTierEngine(_ flags: Kit.Flags.Registry) -> ChargeTierEngine {
        return ChargeTierEngine(
            steps: [
                CapChargeTierAdjuster(cap: 24669.0),
                ChargeTierAcuityOffsetAdjuster(weight: 0.71),
                TieredChargeTierAdjuster(bounds: [4074.0, 4982.0, 7666.0, 9582.0], rates: [0.93, 0.9, 0.9, 1.17]),
                RoundingChargeTierAdjuster(step: 5.0),
                FlaggedChargeTierAdjuster(flags: flags, flag: "charge-tier-adaptive", percent: -1.7),
                NameChargeTierAdjuster(factors: ["north": 1.15, "online": 1.23]),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 13370.9
        )
    }
}
