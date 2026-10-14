import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the bed board notice calculation.
    protocol BedBoardNoticeModifier {
        func describe() -> String
        func adjust(_ item: BedBoardNotice, value: Double) -> Double
    }

    final class RoundingBedBoardNoticeAdjuster: BedBoardNoticeModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BedBoardNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapBedBoardNoticeAdjuster: BedBoardNoticeModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BedBoardNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedBedBoardNoticeAdjuster: BedBoardNoticeModifier {
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

        func adjust(_ item: BedBoardNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredBedBoardNoticeAdjuster: BedBoardNoticeModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BedBoardNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumBedBoardNoticeAdjuster: BedBoardNoticeModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BedBoardNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RegionBedBoardNoticeAdjuster: BedBoardNoticeModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: BedBoardNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the bed board notice steps in order and keeps a trace of each.
    final class BedBoardNoticeEngine {
        var steps: [any BedBoardNoticeModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BedBoardNoticeModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BedBoardNotice) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BedBoardNoticeModifier = steps[index]
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

        func evaluateAll(_ items: [BedBoardNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBedBoardNoticeEngine(_ flags: Kit.Flags.Registry) -> BedBoardNoticeEngine {
        return BedBoardNoticeEngine(
            steps: [
                RoundingBedBoardNoticeAdjuster(step: 1.0),
                CapBedBoardNoticeAdjuster(cap: 27299.0),
                FlaggedBedBoardNoticeAdjuster(flags: flags, flag: "bed-board-notice-weighted", percent: -0.9),
                TieredBedBoardNoticeAdjuster(bounds: [4037.0, 5571.0, 6456.0, 9725.0], rates: [1.08, 0.94, 1.1, 1.05]),
                MinimumBedBoardNoticeAdjuster(minimum: 16.6),
                RegionBedBoardNoticeAdjuster(factors: ["west": 0.71, "retail": 0.93]),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 1891.9
        )
    }
}
