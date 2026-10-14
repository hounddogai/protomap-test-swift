import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the bed board profile calculation.
    protocol BedBoardProfileAdjuster {
        func describe() -> String
        func adjust(_ item: BedBoardProfile, value: Double) -> Double
    }

    final class BedBoardProfileWindowDaysOffsetAdjuster: BedBoardProfileAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: BedBoardProfile, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class PercentBedBoardProfileAdjuster: BedBoardProfileAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BedBoardProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapBedBoardProfileAdjuster: BedBoardProfileAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BedBoardProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredBedBoardProfileAdjuster: BedBoardProfileAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BedBoardProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingBedBoardProfileAdjuster: BedBoardProfileAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BedBoardProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedBedBoardProfileAdjuster: BedBoardProfileAdjuster {
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

        func adjust(_ item: BedBoardProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the bed board profile steps in order and keeps a trace of each.
    final class BedBoardProfileEngine {
        var steps: [any BedBoardProfileAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BedBoardProfileAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BedBoardProfile) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any BedBoardProfileAdjuster = steps[index]
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

        func evaluateAll(_ items: [BedBoardProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBedBoardProfileEngine(_ flags: Kit.Flags.Registry) -> BedBoardProfileEngine {
        return BedBoardProfileEngine(
            steps: [
                BedBoardProfileWindowDaysOffsetAdjuster(weight: 1.54),
                PercentBedBoardProfileAdjuster(percent: -16.0),
                CapBedBoardProfileAdjuster(cap: 21869.0),
                TieredBedBoardProfileAdjuster(bounds: [8484.0, 8752.0], rates: [0.88, 1.09]),
                RoundingBedBoardProfileAdjuster(step: 0.25),
                FlaggedBedBoardProfileAdjuster(flags: flags, flag: "bed-board-profile-capped", percent: 2.7),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 77384.1
        )
    }
}
