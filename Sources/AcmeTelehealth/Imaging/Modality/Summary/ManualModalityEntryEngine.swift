import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the manual modality entry calculation.
    protocol ManualModalityEntryFactor {
        func describe() -> String
        func adjust(_ item: ManualModalityEntry, value: Double) -> Double
    }

    final class PercentManualModalityEntryAdjuster: ManualModalityEntryFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualModalityEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumManualModalityEntryAdjuster: ManualModalityEntryFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualModalityEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingManualModalityEntryAdjuster: ManualModalityEntryFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualModalityEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapManualModalityEntryAdjuster: ManualModalityEntryFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualModalityEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedManualModalityEntryAdjuster: ManualModalityEntryFactor {
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

        func adjust(_ item: ManualModalityEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ManualModalityEntryStartsAtOffsetAdjuster: ManualModalityEntryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: ManualModalityEntry, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    /// Runs the manual modality entry steps in order and keeps a trace of each.
    final class ManualModalityEntryEngine {
        var steps: [any ManualModalityEntryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualModalityEntryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ManualModalityEntry) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualModalityEntryFactor = steps[index]
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

        func evaluateAll(_ items: [ManualModalityEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultManualModalityEntryEngine(_ flags: Kit.Flags.Registry) -> ManualModalityEntryEngine {
        return ManualModalityEntryEngine(
            steps: [
                PercentManualModalityEntryAdjuster(percent: 6.0),
                MinimumManualModalityEntryAdjuster(minimum: 36.1),
                RoundingManualModalityEntryAdjuster(step: 0.1),
                CapManualModalityEntryAdjuster(cap: 20782.0),
                FlaggedManualModalityEntryAdjuster(flags: flags, flag: "manual-modality-entry-weighted", percent: 6.8),
                ManualModalityEntryStartsAtOffsetAdjuster(weight: 1.5),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 58618.6
        )
    }
}
