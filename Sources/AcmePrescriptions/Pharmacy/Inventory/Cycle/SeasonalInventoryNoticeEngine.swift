import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the seasonal inventory notice calculation.
    protocol SeasonalInventoryNoticeAdjuster {
        func describe() -> String
        func adjust(_ item: SeasonalInventoryNotice, value: Double) -> Double
    }

    final class PercentSeasonalInventoryNoticeAdjuster: SeasonalInventoryNoticeAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalInventoryNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedSeasonalInventoryNoticeAdjuster: SeasonalInventoryNoticeAdjuster {
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

        func adjust(_ item: SeasonalInventoryNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumSeasonalInventoryNoticeAdjuster: SeasonalInventoryNoticeAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalInventoryNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the seasonal inventory notice steps in order and keeps a trace of each.
    final class SeasonalInventoryNoticeEngine {
        var steps: [any SeasonalInventoryNoticeAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalInventoryNoticeAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalInventoryNotice) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalInventoryNoticeAdjuster = steps[index]
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

        func evaluateAll(_ items: [SeasonalInventoryNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalInventoryNoticeEngine(_ flags: Kit.Flags.Registry) -> SeasonalInventoryNoticeEngine {
        return SeasonalInventoryNoticeEngine(
            steps: [
                PercentSeasonalInventoryNoticeAdjuster(percent: 16.8),
                FlaggedSeasonalInventoryNoticeAdjuster(
                    flags: flags,
                    flag: "seasonal-inventory-notice-strict",
                    percent: 7.1
                ),
                MinimumSeasonalInventoryNoticeAdjuster(minimum: 46.7),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 59895.9
        )
    }
}
