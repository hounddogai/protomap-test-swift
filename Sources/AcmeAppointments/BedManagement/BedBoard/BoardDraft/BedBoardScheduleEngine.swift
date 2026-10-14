import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the bed board schedule calculation.
    protocol BedBoardScheduleAdjuster {
        func describe() -> String
        func adjust(_ item: BedBoardSchedule, value: Double) -> Double
    }

    final class TieredBedBoardScheduleAdjuster: BedBoardScheduleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BedBoardSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class BedBoardScheduleRetriesOffsetAdjuster: BedBoardScheduleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: BedBoardSchedule, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class MinimumBedBoardScheduleAdjuster: BedBoardScheduleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BedBoardSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedBedBoardScheduleAdjuster: BedBoardScheduleAdjuster {
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

        func adjust(_ item: BedBoardSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingBedBoardScheduleAdjuster: BedBoardScheduleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BedBoardSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the bed board schedule steps in order and keeps a trace of each.
    final class BedBoardScheduleEngine {
        var steps: [any BedBoardScheduleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BedBoardScheduleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BedBoardSchedule) -> Double {
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

        func evaluateAll(_ items: [BedBoardSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBedBoardScheduleEngine(_ flags: Kit.Flags.Registry) -> BedBoardScheduleEngine {
        return BedBoardScheduleEngine(
            steps: [
                TieredBedBoardScheduleAdjuster(
                    bounds: [910.0, 3812.0, 7268.0, 8559.0],
                    rates: [0.84, 0.89, 1.19, 0.83]
                ),
                BedBoardScheduleRetriesOffsetAdjuster(weight: 0.49),
                MinimumBedBoardScheduleAdjuster(minimum: 43.6),
                FlaggedBedBoardScheduleAdjuster(flags: flags, flag: "bed-board-schedule-seasonal", percent: 5.2),
                RoundingBedBoardScheduleAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 8526.3
        )
    }
}
