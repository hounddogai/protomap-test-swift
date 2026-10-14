import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the lenient census record calculation.
    protocol LenientCensusRecordStep {
        func describe() -> String
        func adjust(_ item: LenientCensusRecord, value: Double) -> Double
    }

    final class FlaggedLenientCensusRecordAdjuster: LenientCensusRecordStep {
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

        func adjust(_ item: LenientCensusRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLenientCensusRecordAdjuster: LenientCensusRecordStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientCensusRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLenientCensusRecordAdjuster: LenientCensusRecordStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientCensusRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient census record steps in order and keeps a trace of each.
    final class LenientCensusRecordEngine {
        var steps: [any LenientCensusRecordStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientCensusRecordStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientCensusRecord) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientCensusRecordStep = steps[index]
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

        func evaluateAll(_ items: [LenientCensusRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientCensusRecordEngine(_ flags: Kit.Flags.Registry) -> LenientCensusRecordEngine {
        return LenientCensusRecordEngine(
            steps: [
                FlaggedLenientCensusRecordAdjuster(flags: flags, flag: "lenient-census-record-fallback", percent: 2.4),
                MinimumLenientCensusRecordAdjuster(minimum: 3.7),
                PercentLenientCensusRecordAdjuster(percent: 15.4),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 95883.7
        )
    }
}
