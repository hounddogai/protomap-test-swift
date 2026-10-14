import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the bed board request calculation.
    protocol BedBoardRequestStep {
        func describe() -> String
        func adjust(_ item: BedBoardRequest, value: Double) -> Double
    }

    final class CapBedBoardRequestAdjuster: BedBoardRequestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BedBoardRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedBedBoardRequestAdjuster: BedBoardRequestStep {
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

        func adjust(_ item: BedBoardRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingBedBoardRequestAdjuster: BedBoardRequestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BedBoardRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the bed board request steps in order and keeps a trace of each.
    final class BedBoardRequestEngine {
        var steps: [any BedBoardRequestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BedBoardRequestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BedBoardRequest) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any BedBoardRequestStep = steps[index]
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

        func evaluateAll(_ items: [BedBoardRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBedBoardRequestEngine(_ flags: Kit.Flags.Registry) -> BedBoardRequestEngine {
        return BedBoardRequestEngine(
            steps: [
                CapBedBoardRequestAdjuster(cap: 25121.0),
                FlaggedBedBoardRequestAdjuster(flags: flags, flag: "bed-board-request-pending", percent: -6.1),
                RoundingBedBoardRequestAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 54965.6
        )
    }
}
