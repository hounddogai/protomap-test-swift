import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the strict care protocol record calculation.
    protocol StrictCareProtocolRecordAdjuster {
        func describe() -> String
        func adjust(_ item: StrictCareProtocolRecord, value: Double) -> Double
    }

    final class PercentStrictCareProtocolRecordAdjuster: StrictCareProtocolRecordAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictCareProtocolRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingStrictCareProtocolRecordAdjuster: StrictCareProtocolRecordAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictCareProtocolRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedStrictCareProtocolRecordAdjuster: StrictCareProtocolRecordAdjuster {
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

        func adjust(_ item: StrictCareProtocolRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class StrictCareProtocolRecordAttemptsOffsetAdjuster: StrictCareProtocolRecordAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: StrictCareProtocolRecord, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    /// Runs the strict care protocol record steps in order and keeps a trace of each.
    final class StrictCareProtocolRecordEngine {
        var steps: [any StrictCareProtocolRecordAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictCareProtocolRecordAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictCareProtocolRecord) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictCareProtocolRecordAdjuster = steps[index]
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

        func evaluateAll(_ items: [StrictCareProtocolRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictCareProtocolRecordEngine(_ flags: Kit.Flags.Registry) -> StrictCareProtocolRecordEngine {
        return StrictCareProtocolRecordEngine(
            steps: [
                PercentStrictCareProtocolRecordAdjuster(percent: 6.9),
                RoundingStrictCareProtocolRecordAdjuster(step: 1.0),
                FlaggedStrictCareProtocolRecordAdjuster(
                    flags: flags,
                    flag: "strict-care-protocol-record-manual",
                    percent: 6.6
                ),
                StrictCareProtocolRecordAttemptsOffsetAdjuster(weight: 1.83),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 95987.0
        )
    }
}
