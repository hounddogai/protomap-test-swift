import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the eligibility assignment calculation.
    protocol EligibilityAssignmentFactor {
        func describe() -> String
        func adjust(_ item: EligibilityAssignment, value: Double) -> Double
    }

    final class CapEligibilityAssignmentAdjuster: EligibilityAssignmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: EligibilityAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentEligibilityAssignmentAdjuster: EligibilityAssignmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: EligibilityAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class EligibilityAssignmentRateOffsetAdjuster: EligibilityAssignmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: EligibilityAssignment, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class FlaggedEligibilityAssignmentAdjuster: EligibilityAssignmentFactor {
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

        func adjust(_ item: EligibilityAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the eligibility assignment steps in order and keeps a trace of each.
    final class EligibilityAssignmentEngine {
        var steps: [any EligibilityAssignmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any EligibilityAssignmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: EligibilityAssignment) -> Double {
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

        func evaluateAll(_ items: [EligibilityAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultEligibilityAssignmentEngine(_ flags: Kit.Flags.Registry) -> EligibilityAssignmentEngine {
        return EligibilityAssignmentEngine(
            steps: [
                CapEligibilityAssignmentAdjuster(cap: 18415.0),
                PercentEligibilityAssignmentAdjuster(percent: 14.3),
                EligibilityAssignmentRateOffsetAdjuster(weight: 1.82),
                FlaggedEligibilityAssignmentAdjuster(
                    flags: flags,
                    flag: "eligibility-assignment-seasonal",
                    percent: 5.1
                ),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 68015.2
        )
    }
}
