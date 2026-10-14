import AcmePlatform
import Foundation

extension Labs {
    /// One step of the reference range slot calculation.
    protocol ReferenceRangeSlotModifier {
        func describe() -> String
        func adjust(_ item: ReferenceRangeSlot, value: Double) -> Double
    }

    final class FlaggedReferenceRangeSlotAdjuster: ReferenceRangeSlotModifier {
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

        func adjust(_ item: ReferenceRangeSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ReferenceRangeSlotScoreOffsetAdjuster: ReferenceRangeSlotModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: ReferenceRangeSlot, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class RoundingReferenceRangeSlotAdjuster: ReferenceRangeSlotModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferenceRangeSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentReferenceRangeSlotAdjuster: ReferenceRangeSlotModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferenceRangeSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredReferenceRangeSlotAdjuster: ReferenceRangeSlotModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferenceRangeSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapReferenceRangeSlotAdjuster: ReferenceRangeSlotModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReferenceRangeSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the reference range slot steps in order and keeps a trace of each.
    final class ReferenceRangeSlotEngine {
        var steps: [any ReferenceRangeSlotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferenceRangeSlotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ReferenceRangeSlot) -> Double {
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

        func evaluateAll(_ items: [ReferenceRangeSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultReferenceRangeSlotEngine(_ flags: Kit.Flags.Registry) -> ReferenceRangeSlotEngine {
        return ReferenceRangeSlotEngine(
            steps: [
                FlaggedReferenceRangeSlotAdjuster(flags: flags, flag: "reference-range-slot-strict", percent: -1.6),
                ReferenceRangeSlotScoreOffsetAdjuster(weight: 1.92),
                RoundingReferenceRangeSlotAdjuster(step: 0.5),
                PercentReferenceRangeSlotAdjuster(percent: -21.2),
                TieredReferenceRangeSlotAdjuster(
                    bounds: [3714.0, 6817.0, 8474.0, 9669.0],
                    rates: [1.04, 0.83, 1.04, 0.87]
                ),
                CapReferenceRangeSlotAdjuster(cap: 25374.0),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 26986.4
        )
    }
}
