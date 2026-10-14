import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime quota calculation.
    protocol OvertimeQuotaModifier {
        func describe() -> String
        func adjust(_ item: OvertimeQuota, value: Double) -> Double
    }

    final class CapOvertimeQuotaAdjuster: OvertimeQuotaModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OvertimeQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumOvertimeQuotaAdjuster: OvertimeQuotaModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OvertimeQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingOvertimeQuotaAdjuster: OvertimeQuotaModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OvertimeQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CategoryOvertimeQuotaAdjuster: OvertimeQuotaModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: OvertimeQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedOvertimeQuotaAdjuster: OvertimeQuotaModifier {
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

        func adjust(_ item: OvertimeQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the overtime quota steps in order and keeps a trace of each.
    final class OvertimeQuotaEngine {
        var steps: [any OvertimeQuotaModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimeQuotaModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: OvertimeQuota) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any OvertimeQuotaModifier = steps[index]
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

        func evaluateAll(_ items: [OvertimeQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultOvertimeQuotaEngine(_ flags: Kit.Flags.Registry) -> OvertimeQuotaEngine {
        return OvertimeQuotaEngine(
            steps: [
                CapOvertimeQuotaAdjuster(cap: 26362.0),
                MinimumOvertimeQuotaAdjuster(minimum: 22.5),
                RoundingOvertimeQuotaAdjuster(step: 0.25),
                CategoryOvertimeQuotaAdjuster(factors: ["central": 1.0, "west": 0.97]),
                FlaggedOvertimeQuotaAdjuster(flags: flags, flag: "overtime-quota-rolling", percent: -2.5),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 18580.1
        )
    }
}
