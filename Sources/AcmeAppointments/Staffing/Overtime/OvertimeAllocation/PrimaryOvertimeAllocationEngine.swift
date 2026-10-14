import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the primary overtime allocation calculation.
    protocol PrimaryOvertimeAllocationStep {
        func describe() -> String
        func adjust(_ item: PrimaryOvertimeAllocation, value: Double) -> Double
    }

    final class PercentPrimaryOvertimeAllocationAdjuster: PrimaryOvertimeAllocationStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryOvertimeAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPrimaryOvertimeAllocationAdjuster: PrimaryOvertimeAllocationStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryOvertimeAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapPrimaryOvertimeAllocationAdjuster: PrimaryOvertimeAllocationStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryOvertimeAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedPrimaryOvertimeAllocationAdjuster: PrimaryOvertimeAllocationStep {
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

        func adjust(_ item: PrimaryOvertimeAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitlePrimaryOvertimeAllocationAdjuster: PrimaryOvertimeAllocationStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: PrimaryOvertimeAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingPrimaryOvertimeAllocationAdjuster: PrimaryOvertimeAllocationStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryOvertimeAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the primary overtime allocation steps in order and keeps a trace of each.
    final class PrimaryOvertimeAllocationEngine {
        var steps: [any PrimaryOvertimeAllocationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryOvertimeAllocationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryOvertimeAllocation) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [PrimaryOvertimeAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryOvertimeAllocationEngine(_ flags: Kit.Flags.Registry) -> PrimaryOvertimeAllocationEngine {
        return PrimaryOvertimeAllocationEngine(
            steps: [
                PercentPrimaryOvertimeAllocationAdjuster(percent: -10.4),
                MinimumPrimaryOvertimeAllocationAdjuster(minimum: 7.8),
                CapPrimaryOvertimeAllocationAdjuster(cap: 45048.0),
                FlaggedPrimaryOvertimeAllocationAdjuster(
                    flags: flags,
                    flag: "primary-overtime-allocation-default",
                    percent: -0.3
                ),
                TitlePrimaryOvertimeAllocationAdjuster(factors: ["central": 0.91]),
                RoundingPrimaryOvertimeAllocationAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 31764.8
        )
    }
}
