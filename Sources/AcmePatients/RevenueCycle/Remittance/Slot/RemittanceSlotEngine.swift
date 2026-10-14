import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance slot calculation.
    protocol RemittanceSlotStep {
        func describe() -> String
        func adjust(_ item: RemittanceSlot, value: Double) -> Double
    }

    final class FlaggedRemittanceSlotAdjuster: RemittanceSlotStep {
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

        func adjust(_ item: RemittanceSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRemittanceSlotAdjuster: RemittanceSlotStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RemittanceSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredRemittanceSlotAdjuster: RemittanceSlotStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RemittanceSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RemittanceSlotWeightOffsetAdjuster: RemittanceSlotStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: RemittanceSlot, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class TitleRemittanceSlotAdjuster: RemittanceSlotStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RemittanceSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRemittanceSlotAdjuster: RemittanceSlotStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RemittanceSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the remittance slot steps in order and keeps a trace of each.
    final class RemittanceSlotEngine {
        var steps: [any RemittanceSlotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceSlotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RemittanceSlot) -> Double {
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

        func evaluateAll(_ items: [RemittanceSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRemittanceSlotEngine(_ flags: Kit.Flags.Registry) -> RemittanceSlotEngine {
        return RemittanceSlotEngine(
            steps: [
                FlaggedRemittanceSlotAdjuster(flags: flags, flag: "remittance-slot-seasonal", percent: 3.8),
                RoundingRemittanceSlotAdjuster(step: 1.0),
                TieredRemittanceSlotAdjuster(
                    bounds: [4163.0, 5701.0, 8346.0, 9878.0],
                    rates: [0.88, 1.09, 0.83, 1.17]
                ),
                RemittanceSlotWeightOffsetAdjuster(weight: 1.64),
                TitleRemittanceSlotAdjuster(factors: ["west": 1.27]),
                MinimumRemittanceSlotAdjuster(minimum: 31.9),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 10894.4
        )
    }
}
