import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the program claim calculation.
    protocol ProgramClaimModifier {
        func describe() -> String
        func adjust(_ item: ProgramClaim, value: Double) -> Double
    }

    final class PercentProgramClaimAdjuster: ProgramClaimModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProgramClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumProgramClaimAdjuster: ProgramClaimModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ProgramClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedProgramClaimAdjuster: ProgramClaimModifier {
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

        func adjust(_ item: ProgramClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the program claim steps in order and keeps a trace of each.
    final class ProgramClaimEngine {
        var steps: [any ProgramClaimModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProgramClaimModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ProgramClaim) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ProgramClaimModifier = steps[index]
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

        func evaluateAll(_ items: [ProgramClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultProgramClaimEngine(_ flags: Kit.Flags.Registry) -> ProgramClaimEngine {
        return ProgramClaimEngine(
            steps: [
                PercentProgramClaimAdjuster(percent: 24.2),
                MinimumProgramClaimAdjuster(minimum: 11.2),
                FlaggedProgramClaimAdjuster(flags: flags, flag: "program-claim-batched", percent: 2.3),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 53125.2
        )
    }
}
