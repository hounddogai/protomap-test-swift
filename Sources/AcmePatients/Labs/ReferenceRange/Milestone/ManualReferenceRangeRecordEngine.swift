import AcmePlatform
import Foundation

extension Labs {
    /// One step of the manual reference range record calculation.
    protocol ManualReferenceRangeRecordAdjuster {
        func describe() -> String
        func adjust(_ item: ManualReferenceRangeRecord, value: Double) -> Double
    }

    final class ManualReferenceRangeRecordCopayOffsetAdjuster: ManualReferenceRangeRecordAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: ManualReferenceRangeRecord, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class CapManualReferenceRangeRecordAdjuster: ManualReferenceRangeRecordAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualReferenceRangeRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedManualReferenceRangeRecordAdjuster: ManualReferenceRangeRecordAdjuster {
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

        func adjust(_ item: ManualReferenceRangeRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumManualReferenceRangeRecordAdjuster: ManualReferenceRangeRecordAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualReferenceRangeRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingManualReferenceRangeRecordAdjuster: ManualReferenceRangeRecordAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualReferenceRangeRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the manual reference range record steps in order and keeps a trace of each.
    final class ManualReferenceRangeRecordEngine {
        var steps: [any ManualReferenceRangeRecordAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualReferenceRangeRecordAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualReferenceRangeRecord) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [ManualReferenceRangeRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualReferenceRangeRecordEngine(_ flags: Kit.Flags.Registry) -> ManualReferenceRangeRecordEngine {
        return ManualReferenceRangeRecordEngine(
            steps: [
                ManualReferenceRangeRecordCopayOffsetAdjuster(weight: 0.65),
                CapManualReferenceRangeRecordAdjuster(cap: 41290.0),
                FlaggedManualReferenceRangeRecordAdjuster(
                    flags: flags,
                    flag: "manual-reference-range-record-adaptive",
                    percent: 7.4
                ),
                MinimumManualReferenceRangeRecordAdjuster(minimum: 10.3),
                RoundingManualReferenceRangeRecordAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 99013.1
        )
    }
}
