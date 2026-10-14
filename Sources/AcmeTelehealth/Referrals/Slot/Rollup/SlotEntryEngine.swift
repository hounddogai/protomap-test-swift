import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot entry calculation.
    protocol SlotEntryAdjuster {
        func describe() -> String
        func adjust(_ item: SlotEntry, value: Double) -> Double
    }

    final class SegmentSlotEntryAdjuster: SlotEntryAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: SlotEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredSlotEntryAdjuster: SlotEntryAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SlotEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapSlotEntryAdjuster: SlotEntryAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SlotEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SlotEntryScoreOffsetAdjuster: SlotEntryAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: SlotEntry, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class FlaggedSlotEntryAdjuster: SlotEntryAdjuster {
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

        func adjust(_ item: SlotEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumSlotEntryAdjuster: SlotEntryAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SlotEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the slot entry steps in order and keeps a trace of each.
    final class SlotEntryEngine {
        var steps: [any SlotEntryAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotEntryAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SlotEntry) -> Double {
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

        func evaluateAll(_ items: [SlotEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSlotEntryEngine(_ flags: Kit.Flags.Registry) -> SlotEntryEngine {
        return SlotEntryEngine(
            steps: [
                SegmentSlotEntryAdjuster(factors: ["east": 0.94, "west": 1.35]),
                TieredSlotEntryAdjuster(bounds: [2722.0, 3580.0, 4410.0], rates: [1.04, 1.09, 0.98]),
                CapSlotEntryAdjuster(cap: 29656.0),
                SlotEntryScoreOffsetAdjuster(weight: 1.36),
                FlaggedSlotEntryAdjuster(flags: flags, flag: "slot-entry-scheduled", percent: 1.8),
                MinimumSlotEntryAdjuster(minimum: 46.6),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 47808.7
        )
    }
}
