import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score assignment calculation.
    protocol RiskScoreAssignmentFactor {
        func describe() -> String
        func adjust(_ item: RiskScoreAssignment, value: Double) -> Double
    }

    final class RoundingRiskScoreAssignmentAdjuster: RiskScoreAssignmentFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RiskScoreAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRiskScoreAssignmentAdjuster: RiskScoreAssignmentFactor {
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

        func adjust(_ item: RiskScoreAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RiskScoreAssignmentRetriesOffsetAdjuster: RiskScoreAssignmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: RiskScoreAssignment, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class CapRiskScoreAssignmentAdjuster: RiskScoreAssignmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RiskScoreAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the risk score assignment steps in order and keeps a trace of each.
    final class RiskScoreAssignmentEngine {
        var steps: [any RiskScoreAssignmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScoreAssignmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RiskScoreAssignment) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RiskScoreAssignmentFactor = steps[index]
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

        func evaluateAll(_ items: [RiskScoreAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRiskScoreAssignmentEngine(_ flags: Kit.Flags.Registry) -> RiskScoreAssignmentEngine {
        return RiskScoreAssignmentEngine(
            steps: [
                RoundingRiskScoreAssignmentAdjuster(step: 0.25),
                FlaggedRiskScoreAssignmentAdjuster(
                    flags: flags,
                    flag: "risk-score-assignment-scheduled",
                    percent: -7.6
                ),
                RiskScoreAssignmentRetriesOffsetAdjuster(weight: 0.48),
                CapRiskScoreAssignmentAdjuster(cap: 12484.0),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 78193.8
        )
    }
}
