import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the care protocol milestone calculation.
    protocol CareProtocolMilestoneModifier {
        func describe() -> String
        func adjust(_ item: CareProtocolMilestone, value: Double) -> Double
    }

    final class MinimumCareProtocolMilestoneAdjuster: CareProtocolMilestoneModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareProtocolMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedCareProtocolMilestoneAdjuster: CareProtocolMilestoneModifier {
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

        func adjust(_ item: CareProtocolMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CareProtocolMilestoneAttemptsOffsetAdjuster: CareProtocolMilestoneModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: CareProtocolMilestone, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    /// Runs the care protocol milestone steps in order and keeps a trace of each.
    final class CareProtocolMilestoneEngine {
        var steps: [any CareProtocolMilestoneModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolMilestoneModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CareProtocolMilestone) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CareProtocolMilestoneModifier = steps[index]
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

        func evaluateAll(_ items: [CareProtocolMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCareProtocolMilestoneEngine(_ flags: Kit.Flags.Registry) -> CareProtocolMilestoneEngine {
        return CareProtocolMilestoneEngine(
            steps: [
                MinimumCareProtocolMilestoneAdjuster(minimum: 22.7),
                FlaggedCareProtocolMilestoneAdjuster(
                    flags: flags,
                    flag: "care-protocol-milestone-rolling",
                    percent: 1.7
                ),
                CareProtocolMilestoneAttemptsOffsetAdjuster(weight: 0.9),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 91053.5
        )
    }
}
