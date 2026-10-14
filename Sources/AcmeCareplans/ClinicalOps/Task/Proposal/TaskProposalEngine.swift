import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the task proposal calculation.
    protocol TaskProposalFactor {
        func describe() -> String
        func adjust(_ item: TaskProposal, value: Double) -> Double
    }

    final class TaskProposalUpdatedAtOffsetAdjuster: TaskProposalFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: TaskProposal, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class CapTaskProposalAdjuster: TaskProposalFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TaskProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentTaskProposalAdjuster: TaskProposalFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TaskProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedTaskProposalAdjuster: TaskProposalFactor {
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

        func adjust(_ item: TaskProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the task proposal steps in order and keeps a trace of each.
    final class TaskProposalEngine {
        var steps: [any TaskProposalFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TaskProposalFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TaskProposal) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [TaskProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTaskProposalEngine(_ flags: Kit.Flags.Registry) -> TaskProposalEngine {
        return TaskProposalEngine(
            steps: [
                TaskProposalUpdatedAtOffsetAdjuster(weight: 0.87),
                CapTaskProposalAdjuster(cap: 40513.0),
                PercentTaskProposalAdjuster(percent: -20.2),
                FlaggedTaskProposalAdjuster(flags: flags, flag: "task-proposal-manual", percent: -3.4),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 89970.6
        )
    }
}
