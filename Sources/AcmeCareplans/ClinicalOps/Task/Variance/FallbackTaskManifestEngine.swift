import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the fallback task manifest calculation.
    protocol FallbackTaskManifestModifier {
        func describe() -> String
        func adjust(_ item: FallbackTaskManifest, value: Double) -> Double
    }

    final class CapFallbackTaskManifestAdjuster: FallbackTaskManifestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackTaskManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FallbackTaskManifestRatioOffsetAdjuster: FallbackTaskManifestModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: FallbackTaskManifest, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class FlaggedFallbackTaskManifestAdjuster: FallbackTaskManifestModifier {
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

        func adjust(_ item: FallbackTaskManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentFallbackTaskManifestAdjuster: FallbackTaskManifestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackTaskManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilityFallbackTaskManifestAdjuster: FallbackTaskManifestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: FallbackTaskManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the fallback task manifest steps in order and keeps a trace of each.
    final class FallbackTaskManifestEngine {
        var steps: [any FallbackTaskManifestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackTaskManifestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackTaskManifest) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [FallbackTaskManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackTaskManifestEngine(_ flags: Kit.Flags.Registry) -> FallbackTaskManifestEngine {
        return FallbackTaskManifestEngine(
            steps: [
                CapFallbackTaskManifestAdjuster(cap: 37452.0),
                FallbackTaskManifestRatioOffsetAdjuster(weight: 1.72),
                FlaggedFallbackTaskManifestAdjuster(
                    flags: flags,
                    flag: "fallback-task-manifest-primary",
                    percent: -5.8
                ),
                PercentFallbackTaskManifestAdjuster(percent: 23.6),
                FacilityFallbackTaskManifestAdjuster(factors: ["retail": 0.81, "online": 1.05]),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 3189.8
        )
    }
}
