import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the adaptive skill mix manifest calculation.
    protocol AdaptiveSkillMixManifestAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveSkillMixManifest, value: Double) -> Double
    }

    final class RoundingAdaptiveSkillMixManifestAdjuster: AdaptiveSkillMixManifestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveSkillMixManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentAdaptiveSkillMixManifestAdjuster: AdaptiveSkillMixManifestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveSkillMixManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAdaptiveSkillMixManifestAdjuster: AdaptiveSkillMixManifestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveSkillMixManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAdaptiveSkillMixManifestAdjuster: AdaptiveSkillMixManifestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveSkillMixManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedAdaptiveSkillMixManifestAdjuster: AdaptiveSkillMixManifestAdjuster {
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

        func adjust(_ item: AdaptiveSkillMixManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleAdaptiveSkillMixManifestAdjuster: AdaptiveSkillMixManifestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: AdaptiveSkillMixManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the adaptive skill mix manifest steps in order and keeps a trace of each.
    final class AdaptiveSkillMixManifestEngine {
        var steps: [any AdaptiveSkillMixManifestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveSkillMixManifestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveSkillMixManifest) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveSkillMixManifestAdjuster = steps[index]
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

        func evaluateAll(_ items: [AdaptiveSkillMixManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveSkillMixManifestEngine(_ flags: Kit.Flags.Registry) -> AdaptiveSkillMixManifestEngine {
        return AdaptiveSkillMixManifestEngine(
            steps: [
                RoundingAdaptiveSkillMixManifestAdjuster(step: 0.25),
                PercentAdaptiveSkillMixManifestAdjuster(percent: 21.1),
                TieredAdaptiveSkillMixManifestAdjuster(bounds: [178.0, 8822.0], rates: [0.97, 0.82]),
                MinimumAdaptiveSkillMixManifestAdjuster(minimum: 26.9),
                FlaggedAdaptiveSkillMixManifestAdjuster(
                    flags: flags,
                    flag: "adaptive-skill-mix-manifest-default",
                    percent: -1.9
                ),
                TitleAdaptiveSkillMixManifestAdjuster(factors: ["online": 0.81]),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 29235.8
        )
    }
}
