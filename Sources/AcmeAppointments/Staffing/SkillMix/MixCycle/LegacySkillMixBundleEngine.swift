import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the legacy skill mix bundle calculation.
    protocol LegacySkillMixBundleFactor {
        func describe() -> String
        func adjust(_ item: LegacySkillMixBundle, value: Double) -> Double
    }

    final class CapLegacySkillMixBundleAdjuster: LegacySkillMixBundleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacySkillMixBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumLegacySkillMixBundleAdjuster: LegacySkillMixBundleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacySkillMixBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedLegacySkillMixBundleAdjuster: LegacySkillMixBundleFactor {
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

        func adjust(_ item: LegacySkillMixBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the legacy skill mix bundle steps in order and keeps a trace of each.
    final class LegacySkillMixBundleEngine {
        var steps: [any LegacySkillMixBundleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacySkillMixBundleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacySkillMixBundle) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacySkillMixBundleFactor = steps[index]
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

        func evaluateAll(_ items: [LegacySkillMixBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacySkillMixBundleEngine(_ flags: Kit.Flags.Registry) -> LegacySkillMixBundleEngine {
        return LegacySkillMixBundleEngine(
            steps: [
                CapLegacySkillMixBundleAdjuster(cap: 40937.0),
                MinimumLegacySkillMixBundleAdjuster(minimum: 3.5),
                FlaggedLegacySkillMixBundleAdjuster(
                    flags: flags,
                    flag: "legacy-skill-mix-bundle-global",
                    percent: 7.0
                ),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 18482.8
        )
    }
}
