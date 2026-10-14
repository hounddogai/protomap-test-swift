import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial assignment calculation.
    protocol DenialAssignmentStep {
        func describe() -> String
        func adjust(_ item: DenialAssignment, value: Double) -> Double
    }

    final class RoundingDenialAssignmentAdjuster: DenialAssignmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DenialAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LabelDenialAssignmentAdjuster: DenialAssignmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: DenialAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedDenialAssignmentAdjuster: DenialAssignmentStep {
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

        func adjust(_ item: DenialAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDenialAssignmentAdjuster: DenialAssignmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DenialAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapDenialAssignmentAdjuster: DenialAssignmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DenialAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the denial assignment steps in order and keeps a trace of each.
    final class DenialAssignmentEngine {
        var steps: [any DenialAssignmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialAssignmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DenialAssignment) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DenialAssignmentStep = steps[index]
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

        func evaluateAll(_ items: [DenialAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDenialAssignmentEngine(_ flags: Kit.Flags.Registry) -> DenialAssignmentEngine {
        return DenialAssignmentEngine(
            steps: [
                RoundingDenialAssignmentAdjuster(step: 0.1),
                LabelDenialAssignmentAdjuster(factors: ["east": 1.31]),
                FlaggedDenialAssignmentAdjuster(flags: flags, flag: "denial-assignment-rolling", percent: -8.1),
                MinimumDenialAssignmentAdjuster(minimum: 5.9),
                CapDenialAssignmentAdjuster(cap: 37048.0),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 33971.7
        )
    }
}
