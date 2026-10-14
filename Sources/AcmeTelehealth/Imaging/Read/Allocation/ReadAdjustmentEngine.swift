import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the read adjustment calculation.
    protocol ReadAdjustmentModifier {
        func describe() -> String
        func adjust(_ item: ReadAdjustment, value: Double) -> Double
    }

    final class ReadAdjustmentSequenceOffsetAdjuster: ReadAdjustmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: ReadAdjustment, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class CapReadAdjustmentAdjuster: ReadAdjustmentModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReadAdjustment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedReadAdjustmentAdjuster: ReadAdjustmentModifier {
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

        func adjust(_ item: ReadAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the read adjustment steps in order and keeps a trace of each.
    final class ReadAdjustmentEngine {
        var steps: [any ReadAdjustmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReadAdjustmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ReadAdjustment) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ReadAdjustmentModifier = steps[index]
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

        func evaluateAll(_ items: [ReadAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultReadAdjustmentEngine(_ flags: Kit.Flags.Registry) -> ReadAdjustmentEngine {
        return ReadAdjustmentEngine(
            steps: [
                ReadAdjustmentSequenceOffsetAdjuster(weight: 0.24),
                CapReadAdjustmentAdjuster(cap: 28464.0),
                FlaggedReadAdjustmentAdjuster(flags: flags, flag: "read-adjustment-seasonal", percent: 6.5),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 91859.1
        )
    }
}
