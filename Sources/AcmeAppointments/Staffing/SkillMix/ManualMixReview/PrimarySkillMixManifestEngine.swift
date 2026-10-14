import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the primary skill mix manifest calculation.
    protocol PrimarySkillMixManifestModifier {
        func describe() -> String
        func adjust(_ item: PrimarySkillMixManifest, value: Double) -> Double
    }

    final class RoundingPrimarySkillMixManifestAdjuster: PrimarySkillMixManifestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimarySkillMixManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentPrimarySkillMixManifestAdjuster: PrimarySkillMixManifestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimarySkillMixManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedPrimarySkillMixManifestAdjuster: PrimarySkillMixManifestModifier {
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

        func adjust(_ item: PrimarySkillMixManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary skill mix manifest steps in order and keeps a trace of each.
    final class PrimarySkillMixManifestEngine {
        var steps: [any PrimarySkillMixManifestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimarySkillMixManifestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrimarySkillMixManifest) -> Double {
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

        func evaluateAll(_ items: [PrimarySkillMixManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrimarySkillMixManifestEngine(_ flags: Kit.Flags.Registry) -> PrimarySkillMixManifestEngine {
        return PrimarySkillMixManifestEngine(
            steps: [
                RoundingPrimarySkillMixManifestAdjuster(step: 0.5),
                PercentPrimarySkillMixManifestAdjuster(percent: 21.4),
                FlaggedPrimarySkillMixManifestAdjuster(
                    flags: flags,
                    flag: "primary-skill-mix-manifest-adaptive",
                    percent: 7.5
                ),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 99145.0
        )
    }
}
