import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime slot calculation.
    protocol OvertimeSlotFactor {
        func describe() -> String
        func adjust(_ item: OvertimeSlot, value: Double) -> Double
    }

    final class OvertimeSlotScoreOffsetAdjuster: OvertimeSlotFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: OvertimeSlot, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class RoundingOvertimeSlotAdjuster: OvertimeSlotFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OvertimeSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedOvertimeSlotAdjuster: OvertimeSlotFactor {
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

        func adjust(_ item: OvertimeSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the overtime slot steps in order and keeps a trace of each.
    final class OvertimeSlotEngine {
        var steps: [any OvertimeSlotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimeSlotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: OvertimeSlot) -> Double {
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

        func evaluateAll(_ items: [OvertimeSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultOvertimeSlotEngine(_ flags: Kit.Flags.Registry) -> OvertimeSlotEngine {
        return OvertimeSlotEngine(
            steps: [
                OvertimeSlotScoreOffsetAdjuster(weight: 1.15),
                RoundingOvertimeSlotAdjuster(step: 5.0),
                FlaggedOvertimeSlotAdjuster(flags: flags, flag: "overtime-slot-regional", percent: -2.7),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 62361.1
        )
    }
}
