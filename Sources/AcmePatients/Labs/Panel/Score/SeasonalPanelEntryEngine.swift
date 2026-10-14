import AcmePlatform
import Foundation

extension Labs {
    /// One step of the seasonal panel entry calculation.
    protocol SeasonalPanelEntryFactor {
        func describe() -> String
        func adjust(_ item: SeasonalPanelEntry, value: Double) -> Double
    }

    final class SeasonalPanelEntryPriorityOffsetAdjuster: SeasonalPanelEntryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: SeasonalPanelEntry, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class MinimumSeasonalPanelEntryAdjuster: SeasonalPanelEntryFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalPanelEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedSeasonalPanelEntryAdjuster: SeasonalPanelEntryFactor {
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

        func adjust(_ item: SeasonalPanelEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSeasonalPanelEntryAdjuster: SeasonalPanelEntryFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalPanelEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingSeasonalPanelEntryAdjuster: SeasonalPanelEntryFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalPanelEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the seasonal panel entry steps in order and keeps a trace of each.
    final class SeasonalPanelEntryEngine {
        var steps: [any SeasonalPanelEntryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalPanelEntryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalPanelEntry) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalPanelEntryFactor = steps[index]
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

        func evaluateAll(_ items: [SeasonalPanelEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalPanelEntryEngine(_ flags: Kit.Flags.Registry) -> SeasonalPanelEntryEngine {
        return SeasonalPanelEntryEngine(
            steps: [
                SeasonalPanelEntryPriorityOffsetAdjuster(weight: 0.71),
                MinimumSeasonalPanelEntryAdjuster(minimum: 4.2),
                FlaggedSeasonalPanelEntryAdjuster(flags: flags, flag: "seasonal-panel-entry-adaptive", percent: 5.3),
                CapSeasonalPanelEntryAdjuster(cap: 25180.0),
                RoundingSeasonalPanelEntryAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 6862.9
        )
    }
}
