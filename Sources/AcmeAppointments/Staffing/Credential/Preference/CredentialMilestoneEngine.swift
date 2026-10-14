import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the credential milestone calculation.
    protocol CredentialMilestoneStep {
        func describe() -> String
        func adjust(_ item: CredentialMilestone, value: Double) -> Double
    }

    final class RoundingCredentialMilestoneAdjuster: CredentialMilestoneStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CredentialMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SourceCredentialMilestoneAdjuster: CredentialMilestoneStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: CredentialMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentCredentialMilestoneAdjuster: CredentialMilestoneStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CredentialMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedCredentialMilestoneAdjuster: CredentialMilestoneStep {
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

        func adjust(_ item: CredentialMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the credential milestone steps in order and keeps a trace of each.
    final class CredentialMilestoneEngine {
        var steps: [any CredentialMilestoneStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CredentialMilestoneStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CredentialMilestone) -> Double {
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

        func evaluateAll(_ items: [CredentialMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCredentialMilestoneEngine(_ flags: Kit.Flags.Registry) -> CredentialMilestoneEngine {
        return CredentialMilestoneEngine(
            steps: [
                RoundingCredentialMilestoneAdjuster(step: 0.05),
                SourceCredentialMilestoneAdjuster(factors: ["online": 0.81]),
                PercentCredentialMilestoneAdjuster(percent: 10.5),
                FlaggedCredentialMilestoneAdjuster(flags: flags, flag: "credential-milestone-pending", percent: -3.6),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 76940.9
        )
    }
}
