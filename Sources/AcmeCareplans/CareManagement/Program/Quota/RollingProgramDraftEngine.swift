import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the rolling program draft calculation.
    protocol RollingProgramDraftStep {
        func describe() -> String
        func adjust(_ item: RollingProgramDraft, value: Double) -> Double
    }

    final class ChannelRollingProgramDraftAdjuster: RollingProgramDraftStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: RollingProgramDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedRollingProgramDraftAdjuster: RollingProgramDraftStep {
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

        func adjust(_ item: RollingProgramDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RollingProgramDraftDiscountOffsetAdjuster: RollingProgramDraftStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: RollingProgramDraft, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    /// Runs the rolling program draft steps in order and keeps a trace of each.
    final class RollingProgramDraftEngine {
        var steps: [any RollingProgramDraftStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingProgramDraftStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingProgramDraft) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [RollingProgramDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingProgramDraftEngine(_ flags: Kit.Flags.Registry) -> RollingProgramDraftEngine {
        return RollingProgramDraftEngine(
            steps: [
                ChannelRollingProgramDraftAdjuster(factors: ["east": 0.74, "central": 0.89]),
                FlaggedRollingProgramDraftAdjuster(flags: flags, flag: "rolling-program-draft-manual", percent: 9.8),
                RollingProgramDraftDiscountOffsetAdjuster(weight: 0.45),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 94079.7
        )
    }
}
