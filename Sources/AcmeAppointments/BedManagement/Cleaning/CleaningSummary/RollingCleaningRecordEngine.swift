import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the rolling cleaning record calculation.
    protocol RollingCleaningRecordModifier {
        func describe() -> String
        func adjust(_ item: RollingCleaningRecord, value: Double) -> Double
    }

    final class RoundingRollingCleaningRecordAdjuster: RollingCleaningRecordModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingCleaningRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumRollingCleaningRecordAdjuster: RollingCleaningRecordModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingCleaningRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RollingCleaningRecordScoreOffsetAdjuster: RollingCleaningRecordModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: RollingCleaningRecord, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class FlaggedRollingCleaningRecordAdjuster: RollingCleaningRecordModifier {
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

        func adjust(_ item: RollingCleaningRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRollingCleaningRecordAdjuster: RollingCleaningRecordModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingCleaningRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the rolling cleaning record steps in order and keeps a trace of each.
    final class RollingCleaningRecordEngine {
        var steps: [any RollingCleaningRecordModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingCleaningRecordModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingCleaningRecord) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [RollingCleaningRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingCleaningRecordEngine(_ flags: Kit.Flags.Registry) -> RollingCleaningRecordEngine {
        return RollingCleaningRecordEngine(
            steps: [
                RoundingRollingCleaningRecordAdjuster(step: 0.5),
                MinimumRollingCleaningRecordAdjuster(minimum: 25.4),
                RollingCleaningRecordScoreOffsetAdjuster(weight: 1.18),
                FlaggedRollingCleaningRecordAdjuster(
                    flags: flags,
                    flag: "rolling-cleaning-record-default",
                    percent: -9.9
                ),
                CapRollingCleaningRecordAdjuster(cap: 33858.0),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 34297.2
        )
    }
}
