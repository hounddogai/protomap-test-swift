import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the default rounding slot calculation.
    protocol DefaultRoundingSlotFactor {
        func describe() -> String
        func adjust(_ item: DefaultRoundingSlot, value: Double) -> Double
    }

    final class FlaggedDefaultRoundingSlotAdjuster: DefaultRoundingSlotFactor {
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

        func adjust(_ item: DefaultRoundingSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDefaultRoundingSlotAdjuster: DefaultRoundingSlotFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultRoundingSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleDefaultRoundingSlotAdjuster: DefaultRoundingSlotFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: DefaultRoundingSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentDefaultRoundingSlotAdjuster: DefaultRoundingSlotFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultRoundingSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDefaultRoundingSlotAdjuster: DefaultRoundingSlotFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultRoundingSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the default rounding slot steps in order and keeps a trace of each.
    final class DefaultRoundingSlotEngine {
        var steps: [any DefaultRoundingSlotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultRoundingSlotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultRoundingSlot) -> Double {
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

        func evaluateAll(_ items: [DefaultRoundingSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultRoundingSlotEngine(_ flags: Kit.Flags.Registry) -> DefaultRoundingSlotEngine {
        return DefaultRoundingSlotEngine(
            steps: [
                FlaggedDefaultRoundingSlotAdjuster(flags: flags, flag: "default-rounding-slot-tiered", percent: 3.4),
                TieredDefaultRoundingSlotAdjuster(bounds: [531.0, 7705.0, 8276.0], rates: [1.13, 1.17, 1.2]),
                TitleDefaultRoundingSlotAdjuster(factors: ["retail": 1.35, "central": 1.02, "west": 1.06]),
                PercentDefaultRoundingSlotAdjuster(percent: 1.0),
                RoundingDefaultRoundingSlotAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 8003.1
        )
    }
}
