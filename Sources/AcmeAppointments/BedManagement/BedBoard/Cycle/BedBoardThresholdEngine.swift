import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the bed board threshold calculation.
    protocol BedBoardThresholdModifier {
        func describe() -> String
        func adjust(_ item: BedBoardThreshold, value: Double) -> Double
    }

    final class MinimumBedBoardThresholdAdjuster: BedBoardThresholdModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BedBoardThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentBedBoardThresholdAdjuster: BedBoardThresholdModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BedBoardThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingBedBoardThresholdAdjuster: BedBoardThresholdModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BedBoardThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedBedBoardThresholdAdjuster: BedBoardThresholdModifier {
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

        func adjust(_ item: BedBoardThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilityBedBoardThresholdAdjuster: BedBoardThresholdModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: BedBoardThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the bed board threshold steps in order and keeps a trace of each.
    final class BedBoardThresholdEngine {
        var steps: [any BedBoardThresholdModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BedBoardThresholdModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BedBoardThreshold) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BedBoardThresholdModifier = steps[index]
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

        func evaluateAll(_ items: [BedBoardThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBedBoardThresholdEngine(_ flags: Kit.Flags.Registry) -> BedBoardThresholdEngine {
        return BedBoardThresholdEngine(
            steps: [
                MinimumBedBoardThresholdAdjuster(minimum: 34.4),
                PercentBedBoardThresholdAdjuster(percent: 0.8),
                RoundingBedBoardThresholdAdjuster(step: 0.1),
                FlaggedBedBoardThresholdAdjuster(flags: flags, flag: "bed-board-threshold-primary", percent: -9.3),
                FacilityBedBoardThresholdAdjuster(factors: ["north": 1.19]),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 95990.3
        )
    }
}
