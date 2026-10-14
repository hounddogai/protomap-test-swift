import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the pending care gap allocation calculation.
    protocol PendingCareGapAllocationModifier {
        func describe() -> String
        func adjust(_ item: PendingCareGapAllocation, value: Double) -> Double
    }

    final class FlaggedPendingCareGapAllocationAdjuster: PendingCareGapAllocationModifier {
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

        func adjust(_ item: PendingCareGapAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentPendingCareGapAllocationAdjuster: PendingCareGapAllocationModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingCareGapAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPendingCareGapAllocationAdjuster: PendingCareGapAllocationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingCareGapAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitlePendingCareGapAllocationAdjuster: PendingCareGapAllocationModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: PendingCareGapAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the pending care gap allocation steps in order and keeps a trace of each.
    final class PendingCareGapAllocationEngine {
        var steps: [any PendingCareGapAllocationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingCareGapAllocationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingCareGapAllocation) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingCareGapAllocationModifier = steps[index]
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

        func evaluateAll(_ items: [PendingCareGapAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingCareGapAllocationEngine(_ flags: Kit.Flags.Registry) -> PendingCareGapAllocationEngine {
        return PendingCareGapAllocationEngine(
            steps: [
                FlaggedPendingCareGapAllocationAdjuster(
                    flags: flags,
                    flag: "pending-care-gap-allocation-legacy",
                    percent: -4.0
                ),
                PercentPendingCareGapAllocationAdjuster(percent: -5.6),
                RoundingPendingCareGapAllocationAdjuster(step: 0.5),
                TitlePendingCareGapAllocationAdjuster(factors: ["south": 1.14]),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 55140.4
        )
    }
}
