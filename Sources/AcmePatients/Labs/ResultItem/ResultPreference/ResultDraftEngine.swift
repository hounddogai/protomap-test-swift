import AcmePlatform
import Foundation

extension Labs {
    /// One step of the result draft calculation.
    protocol ResultDraftStep {
        func describe() -> String
        func adjust(_ item: ResultDraft, value: Double) -> Double
    }

    final class PercentResultDraftAdjuster: ResultDraftStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ResultDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedResultDraftAdjuster: ResultDraftStep {
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

        func adjust(_ item: ResultDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingResultDraftAdjuster: ResultDraftStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ResultDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the result draft steps in order and keeps a trace of each.
    final class ResultDraftEngine {
        var steps: [any ResultDraftStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ResultDraftStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ResultDraft) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [ResultDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultResultDraftEngine(_ flags: Kit.Flags.Registry) -> ResultDraftEngine {
        return ResultDraftEngine(
            steps: [
                PercentResultDraftAdjuster(percent: -8.8),
                FlaggedResultDraftAdjuster(flags: flags, flag: "result-draft-global", percent: 9.7),
                RoundingResultDraftAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 92248.9
        )
    }
}
