import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the shift summary calculation.
    protocol ShiftSummaryStep {
        func describe() -> String
        func adjust(_ item: ShiftSummary, value: Double) -> Double
    }

    final class CapShiftSummaryAdjuster: ShiftSummaryStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ShiftSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ShiftSummaryBatchSizeOffsetAdjuster: ShiftSummaryStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: ShiftSummary, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class FlaggedShiftSummaryAdjuster: ShiftSummaryStep {
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

        func adjust(_ item: ShiftSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the shift summary steps in order and keeps a trace of each.
    final class ShiftSummaryEngine {
        var steps: [any ShiftSummaryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ShiftSummaryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ShiftSummary) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [ShiftSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultShiftSummaryEngine(_ flags: Kit.Flags.Registry) -> ShiftSummaryEngine {
        return ShiftSummaryEngine(
            steps: [
                CapShiftSummaryAdjuster(cap: 14647.0),
                ShiftSummaryBatchSizeOffsetAdjuster(weight: 0.74),
                FlaggedShiftSummaryAdjuster(flags: flags, flag: "shift-summary-global", percent: -5.8),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 95044.4
        )
    }
}
