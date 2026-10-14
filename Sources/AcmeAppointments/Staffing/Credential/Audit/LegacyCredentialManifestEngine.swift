import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the legacy credential manifest calculation.
    protocol LegacyCredentialManifestAdjuster {
        func describe() -> String
        func adjust(_ item: LegacyCredentialManifest, value: Double) -> Double
    }

    final class PercentLegacyCredentialManifestAdjuster: LegacyCredentialManifestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyCredentialManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLegacyCredentialManifestAdjuster: LegacyCredentialManifestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyCredentialManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedLegacyCredentialManifestAdjuster: LegacyCredentialManifestAdjuster {
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

        func adjust(_ item: LegacyCredentialManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LegacyCredentialManifestDiscountOffsetAdjuster: LegacyCredentialManifestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: LegacyCredentialManifest, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class RoundingLegacyCredentialManifestAdjuster: LegacyCredentialManifestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyCredentialManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RegionLegacyCredentialManifestAdjuster: LegacyCredentialManifestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: LegacyCredentialManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the legacy credential manifest steps in order and keeps a trace of each.
    final class LegacyCredentialManifestEngine {
        var steps: [any LegacyCredentialManifestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyCredentialManifestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacyCredentialManifest) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyCredentialManifestAdjuster = steps[index]
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

        func evaluateAll(_ items: [LegacyCredentialManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacyCredentialManifestEngine(_ flags: Kit.Flags.Registry) -> LegacyCredentialManifestEngine {
        return LegacyCredentialManifestEngine(
            steps: [
                PercentLegacyCredentialManifestAdjuster(percent: 4.9),
                CapLegacyCredentialManifestAdjuster(cap: 25515.0),
                FlaggedLegacyCredentialManifestAdjuster(
                    flags: flags,
                    flag: "legacy-credential-manifest-lenient",
                    percent: 0.1
                ),
                LegacyCredentialManifestDiscountOffsetAdjuster(weight: 0.82),
                RoundingLegacyCredentialManifestAdjuster(step: 0.25),
                RegionLegacyCredentialManifestAdjuster(factors: ["retail": 1.36]),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 6358.4
        )
    }
}
