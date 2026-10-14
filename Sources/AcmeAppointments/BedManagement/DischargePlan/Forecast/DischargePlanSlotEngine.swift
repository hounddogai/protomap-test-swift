import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the discharge plan slot calculation.
    protocol DischargePlanSlotAdjuster {
        func describe() -> String
        func adjust(_ item: DischargePlanSlot, value: Double) -> Double
    }

    final class DischargePlanSlotBatchSizeOffsetAdjuster: DischargePlanSlotAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: DischargePlanSlot, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class MinimumDischargePlanSlotAdjuster: DischargePlanSlotAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DischargePlanSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredDischargePlanSlotAdjuster: DischargePlanSlotAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DischargePlanSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedDischargePlanSlotAdjuster: DischargePlanSlotAdjuster {
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

        func adjust(_ item: DischargePlanSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameDischargePlanSlotAdjuster: DischargePlanSlotAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: DischargePlanSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the discharge plan slot steps in order and keeps a trace of each.
    final class DischargePlanSlotEngine {
        var steps: [any DischargePlanSlotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DischargePlanSlotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DischargePlanSlot) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [DischargePlanSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDischargePlanSlotEngine(_ flags: Kit.Flags.Registry) -> DischargePlanSlotEngine {
        return DischargePlanSlotEngine(
            steps: [
                DischargePlanSlotBatchSizeOffsetAdjuster(weight: 0.32),
                MinimumDischargePlanSlotAdjuster(minimum: 5.4),
                TieredDischargePlanSlotAdjuster(
                    bounds: [2809.0, 2834.0, 7168.0, 7910.0],
                    rates: [0.97, 1.04, 1.08, 1.12]
                ),
                FlaggedDischargePlanSlotAdjuster(flags: flags, flag: "discharge-plan-slot-fallback", percent: -8.3),
                NameDischargePlanSlotAdjuster(factors: ["south": 0.88, "retail": 0.8, "north": 1.18]),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 68781.5
        )
    }
}
