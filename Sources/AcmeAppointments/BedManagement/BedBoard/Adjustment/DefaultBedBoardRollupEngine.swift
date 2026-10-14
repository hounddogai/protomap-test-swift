import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the default bed board rollup calculation.
    protocol DefaultBedBoardRollupModifier {
        func describe() -> String
        func adjust(_ item: DefaultBedBoardRollup, value: Double) -> Double
    }

    final class FlaggedDefaultBedBoardRollupAdjuster: DefaultBedBoardRollupModifier {
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

        func adjust(_ item: DefaultBedBoardRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentDefaultBedBoardRollupAdjuster: DefaultBedBoardRollupModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultBedBoardRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DefaultBedBoardRollupEndsAtOffsetAdjuster: DefaultBedBoardRollupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: DefaultBedBoardRollup, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class RoundingDefaultBedBoardRollupAdjuster: DefaultBedBoardRollupModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultBedBoardRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the default bed board rollup steps in order and keeps a trace of each.
    final class DefaultBedBoardRollupEngine {
        var steps: [any DefaultBedBoardRollupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultBedBoardRollupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DefaultBedBoardRollup) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [DefaultBedBoardRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDefaultBedBoardRollupEngine(_ flags: Kit.Flags.Registry) -> DefaultBedBoardRollupEngine {
        return DefaultBedBoardRollupEngine(
            steps: [
                FlaggedDefaultBedBoardRollupAdjuster(
                    flags: flags,
                    flag: "default-bed-board-rollup-scheduled",
                    percent: 4.9
                ),
                PercentDefaultBedBoardRollupAdjuster(percent: 14.5),
                DefaultBedBoardRollupEndsAtOffsetAdjuster(weight: 1.55),
                RoundingDefaultBedBoardRollupAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 79613.4
        )
    }
}
