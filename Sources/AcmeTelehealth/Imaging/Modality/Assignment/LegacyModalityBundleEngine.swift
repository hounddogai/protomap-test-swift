import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the legacy modality bundle calculation.
    protocol LegacyModalityBundleFactor {
        func describe() -> String
        func adjust(_ item: LegacyModalityBundle, value: Double) -> Double
    }

    final class CapLegacyModalityBundleAdjuster: LegacyModalityBundleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyModalityBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingLegacyModalityBundleAdjuster: LegacyModalityBundleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyModalityBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedLegacyModalityBundleAdjuster: LegacyModalityBundleFactor {
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

        func adjust(_ item: LegacyModalityBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LegacyModalityBundleThresholdOffsetAdjuster: LegacyModalityBundleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: LegacyModalityBundle, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class NameLegacyModalityBundleAdjuster: LegacyModalityBundleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: LegacyModalityBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the legacy modality bundle steps in order and keeps a trace of each.
    final class LegacyModalityBundleEngine {
        var steps: [any LegacyModalityBundleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyModalityBundleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyModalityBundle) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [LegacyModalityBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyModalityBundleEngine(_ flags: Kit.Flags.Registry) -> LegacyModalityBundleEngine {
        return LegacyModalityBundleEngine(
            steps: [
                CapLegacyModalityBundleAdjuster(cap: 29374.0),
                RoundingLegacyModalityBundleAdjuster(step: 5.0),
                FlaggedLegacyModalityBundleAdjuster(
                    flags: flags,
                    flag: "legacy-modality-bundle-scheduled",
                    percent: -2.8
                ),
                LegacyModalityBundleThresholdOffsetAdjuster(weight: 1.65),
                NameLegacyModalityBundleAdjuster(factors: ["retail": 1.01, "west": 1.17]),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 95565.1
        )
    }
}
