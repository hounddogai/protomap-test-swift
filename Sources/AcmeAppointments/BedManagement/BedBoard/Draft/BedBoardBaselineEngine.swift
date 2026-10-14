import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the bed board baseline calculation.
    protocol BedBoardBaselineAdjuster {
        func describe() -> String
        func adjust(_ item: BedBoardBaseline, value: Double) -> Double
    }

    final class PercentBedBoardBaselineAdjuster: BedBoardBaselineAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BedBoardBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class BedBoardBaselineMinimumOffsetAdjuster: BedBoardBaselineAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: BedBoardBaseline, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class CapBedBoardBaselineAdjuster: BedBoardBaselineAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BedBoardBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedBedBoardBaselineAdjuster: BedBoardBaselineAdjuster {
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

        func adjust(_ item: BedBoardBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the bed board baseline steps in order and keeps a trace of each.
    final class BedBoardBaselineEngine {
        var steps: [any BedBoardBaselineAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BedBoardBaselineAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BedBoardBaseline) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BedBoardBaselineAdjuster = steps[index]
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

        func evaluateAll(_ items: [BedBoardBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBedBoardBaselineEngine(_ flags: Kit.Flags.Registry) -> BedBoardBaselineEngine {
        return BedBoardBaselineEngine(
            steps: [
                PercentBedBoardBaselineAdjuster(percent: 2.2),
                BedBoardBaselineMinimumOffsetAdjuster(weight: 0.72),
                CapBedBoardBaselineAdjuster(cap: 47866.0),
                FlaggedBedBoardBaselineAdjuster(flags: flags, flag: "bed-board-baseline-weighted", percent: 9.4),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 94889.0
        )
    }
}
