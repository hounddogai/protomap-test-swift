import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the manual care protocol slot calculation.
    protocol ManualCareProtocolSlotModifier {
        func describe() -> String
        func adjust(_ item: ManualCareProtocolSlot, value: Double) -> Double
    }

    final class PercentManualCareProtocolSlotAdjuster: ManualCareProtocolSlotModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualCareProtocolSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ManualCareProtocolSlotRefillsOffsetAdjuster: ManualCareProtocolSlotModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: ManualCareProtocolSlot, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class TieredManualCareProtocolSlotAdjuster: ManualCareProtocolSlotModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualCareProtocolSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapManualCareProtocolSlotAdjuster: ManualCareProtocolSlotModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualCareProtocolSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingManualCareProtocolSlotAdjuster: ManualCareProtocolSlotModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualCareProtocolSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedManualCareProtocolSlotAdjuster: ManualCareProtocolSlotModifier {
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

        func adjust(_ item: ManualCareProtocolSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual care protocol slot steps in order and keeps a trace of each.
    final class ManualCareProtocolSlotEngine {
        var steps: [any ManualCareProtocolSlotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualCareProtocolSlotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualCareProtocolSlot) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualCareProtocolSlotModifier = steps[index]
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

        func evaluateAll(_ items: [ManualCareProtocolSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualCareProtocolSlotEngine(_ flags: Kit.Flags.Registry) -> ManualCareProtocolSlotEngine {
        return ManualCareProtocolSlotEngine(
            steps: [
                PercentManualCareProtocolSlotAdjuster(percent: -2.8),
                ManualCareProtocolSlotRefillsOffsetAdjuster(weight: 1.5),
                TieredManualCareProtocolSlotAdjuster(bounds: [1111.0, 1339.0, 7175.0], rates: [1.1, 0.91, 1.18]),
                CapManualCareProtocolSlotAdjuster(cap: 37554.0),
                RoundingManualCareProtocolSlotAdjuster(step: 0.25),
                FlaggedManualCareProtocolSlotAdjuster(
                    flags: flags,
                    flag: "manual-care-protocol-slot-scheduled",
                    percent: 5.2
                ),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 45966.5
        )
    }
}
