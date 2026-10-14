import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the program target calculation.
    protocol ProgramTargetAdjuster {
        func describe() -> String
        func adjust(_ item: ProgramTarget, value: Double) -> Double
    }

    final class FlaggedProgramTargetAdjuster: ProgramTargetAdjuster {
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

        func adjust(_ item: ProgramTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentProgramTargetAdjuster: ProgramTargetAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProgramTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingProgramTargetAdjuster: ProgramTargetAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProgramTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the program target steps in order and keeps a trace of each.
    final class ProgramTargetEngine {
        var steps: [any ProgramTargetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProgramTargetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ProgramTarget) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [ProgramTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultProgramTargetEngine(_ flags: Kit.Flags.Registry) -> ProgramTargetEngine {
        return ProgramTargetEngine(
            steps: [
                FlaggedProgramTargetAdjuster(flags: flags, flag: "program-target-scheduled", percent: 1.4),
                PercentProgramTargetAdjuster(percent: -1.0),
                RoundingProgramTargetAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 54574.8
        )
    }
}
