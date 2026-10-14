import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the bed board slot calculation.
    protocol BedBoardSlotModifier {
        func describe() -> String
        func adjust(_ item: BedBoardSlot, value: Double) -> Double
    }

    final class CapBedBoardSlotAdjuster: BedBoardSlotModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BedBoardSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredBedBoardSlotAdjuster: BedBoardSlotModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BedBoardSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class BedBoardSlotExpiresAtOffsetAdjuster: BedBoardSlotModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: BedBoardSlot, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class RoundingBedBoardSlotAdjuster: BedBoardSlotModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BedBoardSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedBedBoardSlotAdjuster: BedBoardSlotModifier {
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

        func adjust(_ item: BedBoardSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionBedBoardSlotAdjuster: BedBoardSlotModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: BedBoardSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the bed board slot steps in order and keeps a trace of each.
    final class BedBoardSlotEngine {
        var steps: [any BedBoardSlotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BedBoardSlotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BedBoardSlot) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [BedBoardSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBedBoardSlotEngine(_ flags: Kit.Flags.Registry) -> BedBoardSlotEngine {
        return BedBoardSlotEngine(
            steps: [
                CapBedBoardSlotAdjuster(cap: 44830.0),
                TieredBedBoardSlotAdjuster(bounds: [1278.0, 1692.0, 2605.0], rates: [1.1, 1.2, 1.12]),
                BedBoardSlotExpiresAtOffsetAdjuster(weight: 1.65),
                RoundingBedBoardSlotAdjuster(step: 0.5),
                FlaggedBedBoardSlotAdjuster(flags: flags, flag: "bed-board-slot-default", percent: 2.1),
                RegionBedBoardSlotAdjuster(factors: ["south": 0.8, "west": 1.29]),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 71625.6
        )
    }
}
