import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the legacy interaction manifest calculation.
    protocol LegacyInteractionManifestStep {
        func describe() -> String
        func adjust(_ item: LegacyInteractionManifest, value: Double) -> Double
    }

    final class LegacyInteractionManifestStartsAtOffsetAdjuster: LegacyInteractionManifestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: LegacyInteractionManifest, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class FlaggedLegacyInteractionManifestAdjuster: LegacyInteractionManifestStep {
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

        func adjust(_ item: LegacyInteractionManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLegacyInteractionManifestAdjuster: LegacyInteractionManifestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyInteractionManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LocaleLegacyInteractionManifestAdjuster: LegacyInteractionManifestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: LegacyInteractionManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumLegacyInteractionManifestAdjuster: LegacyInteractionManifestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyInteractionManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingLegacyInteractionManifestAdjuster: LegacyInteractionManifestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyInteractionManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the legacy interaction manifest steps in order and keeps a trace of each.
    final class LegacyInteractionManifestEngine {
        var steps: [any LegacyInteractionManifestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyInteractionManifestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyInteractionManifest) -> Double {
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

        func evaluateAll(_ items: [LegacyInteractionManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyInteractionManifestEngine(_ flags: Kit.Flags.Registry) -> LegacyInteractionManifestEngine {
        return LegacyInteractionManifestEngine(
            steps: [
                LegacyInteractionManifestStartsAtOffsetAdjuster(weight: 0.74),
                FlaggedLegacyInteractionManifestAdjuster(
                    flags: flags,
                    flag: "legacy-interaction-manifest-regional",
                    percent: 8.9
                ),
                CapLegacyInteractionManifestAdjuster(cap: 10218.0),
                LocaleLegacyInteractionManifestAdjuster(factors: ["central": 1.35]),
                MinimumLegacyInteractionManifestAdjuster(minimum: 44.4),
                RoundingLegacyInteractionManifestAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 90637.2
        )
    }
}
