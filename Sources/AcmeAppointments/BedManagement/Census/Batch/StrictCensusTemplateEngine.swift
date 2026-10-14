import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the strict census template calculation.
    protocol StrictCensusTemplateStep {
        func describe() -> String
        func adjust(_ item: StrictCensusTemplate, value: Double) -> Double
    }

    final class PercentStrictCensusTemplateAdjuster: StrictCensusTemplateStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictCensusTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedStrictCensusTemplateAdjuster: StrictCensusTemplateStep {
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

        func adjust(_ item: StrictCensusTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumStrictCensusTemplateAdjuster: StrictCensusTemplateStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictCensusTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the strict census template steps in order and keeps a trace of each.
    final class StrictCensusTemplateEngine {
        var steps: [any StrictCensusTemplateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictCensusTemplateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictCensusTemplate) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [StrictCensusTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictCensusTemplateEngine(_ flags: Kit.Flags.Registry) -> StrictCensusTemplateEngine {
        return StrictCensusTemplateEngine(
            steps: [
                PercentStrictCensusTemplateAdjuster(percent: -10.6),
                FlaggedStrictCensusTemplateAdjuster(
                    flags: flags,
                    flag: "strict-census-template-default",
                    percent: -9.1
                ),
                MinimumStrictCensusTemplateAdjuster(minimum: 33.1),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 24373.9
        )
    }
}
