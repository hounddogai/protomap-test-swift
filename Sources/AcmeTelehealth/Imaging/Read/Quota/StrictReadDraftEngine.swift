import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the strict read draft calculation.
    protocol StrictReadDraftAdjuster {
        func describe() -> String
        func adjust(_ item: StrictReadDraft, value: Double) -> Double
    }

    final class MinimumStrictReadDraftAdjuster: StrictReadDraftAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictReadDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentStrictReadDraftAdjuster: StrictReadDraftAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictReadDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedStrictReadDraftAdjuster: StrictReadDraftAdjuster {
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

        func adjust(_ item: StrictReadDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict read draft steps in order and keeps a trace of each.
    final class StrictReadDraftEngine {
        var steps: [any StrictReadDraftAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictReadDraftAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictReadDraft) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [StrictReadDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictReadDraftEngine(_ flags: Kit.Flags.Registry) -> StrictReadDraftEngine {
        return StrictReadDraftEngine(
            steps: [
                MinimumStrictReadDraftAdjuster(minimum: 27.8),
                PercentStrictReadDraftAdjuster(percent: 12.3),
                FlaggedStrictReadDraftAdjuster(flags: flags, flag: "strict-read-draft-fallback", percent: -2.5),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 22624.1
        )
    }
}
