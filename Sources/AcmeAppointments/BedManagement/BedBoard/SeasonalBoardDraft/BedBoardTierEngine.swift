import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the bed board tier calculation.
    protocol BedBoardTierModifier {
        func describe() -> String
        func adjust(_ item: BedBoardTier, value: Double) -> Double
    }

    final class MinimumBedBoardTierAdjuster: BedBoardTierModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BedBoardTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class BedBoardTierBatchSizeOffsetAdjuster: BedBoardTierModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: BedBoardTier, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class CapBedBoardTierAdjuster: BedBoardTierModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BedBoardTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleBedBoardTierAdjuster: BedBoardTierModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: BedBoardTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedBedBoardTierAdjuster: BedBoardTierModifier {
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

        func adjust(_ item: BedBoardTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the bed board tier steps in order and keeps a trace of each.
    final class BedBoardTierEngine {
        var steps: [any BedBoardTierModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BedBoardTierModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BedBoardTier) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any BedBoardTierModifier = steps[index]
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

        func evaluateAll(_ items: [BedBoardTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBedBoardTierEngine(_ flags: Kit.Flags.Registry) -> BedBoardTierEngine {
        return BedBoardTierEngine(
            steps: [
                MinimumBedBoardTierAdjuster(minimum: 25.5),
                BedBoardTierBatchSizeOffsetAdjuster(weight: 0.22),
                CapBedBoardTierAdjuster(cap: 35369.0),
                TitleBedBoardTierAdjuster(factors: ["west": 1.1]),
                FlaggedBedBoardTierAdjuster(flags: flags, flag: "bed-board-tier-pending", percent: 2.9),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 26292.3
        )
    }
}
