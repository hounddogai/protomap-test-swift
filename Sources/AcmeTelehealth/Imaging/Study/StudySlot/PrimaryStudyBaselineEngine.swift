import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the primary study baseline calculation.
    protocol PrimaryStudyBaselineModifier {
        func describe() -> String
        func adjust(_ item: PrimaryStudyBaseline, value: Double) -> Double
    }

    final class MinimumPrimaryStudyBaselineAdjuster: PrimaryStudyBaselineModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryStudyBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentPrimaryStudyBaselineAdjuster: PrimaryStudyBaselineModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryStudyBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedPrimaryStudyBaselineAdjuster: PrimaryStudyBaselineModifier {
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

        func adjust(_ item: PrimaryStudyBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary study baseline steps in order and keeps a trace of each.
    final class PrimaryStudyBaselineEngine {
        var steps: [any PrimaryStudyBaselineModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryStudyBaselineModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimaryStudyBaseline) -> Double {
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

        func evaluateAll(_ items: [PrimaryStudyBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimaryStudyBaselineEngine(_ flags: Kit.Flags.Registry) -> PrimaryStudyBaselineEngine {
        return PrimaryStudyBaselineEngine(
            steps: [
                MinimumPrimaryStudyBaselineAdjuster(minimum: 43.6),
                PercentPrimaryStudyBaselineAdjuster(percent: 6.4),
                FlaggedPrimaryStudyBaselineAdjuster(
                    flags: flags,
                    flag: "primary-study-baseline-capped",
                    percent: -2.4
                ),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 5866.4
        )
    }
}
