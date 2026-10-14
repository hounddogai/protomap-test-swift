import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the global float pool manifest calculation.
    protocol GlobalFloatPoolManifestAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalFloatPoolManifest, value: Double) -> Double
    }

    final class RoundingGlobalFloatPoolManifestAdjuster: GlobalFloatPoolManifestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalFloatPoolManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumGlobalFloatPoolManifestAdjuster: GlobalFloatPoolManifestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalFloatPoolManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleGlobalFloatPoolManifestAdjuster: GlobalFloatPoolManifestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: GlobalFloatPoolManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapGlobalFloatPoolManifestAdjuster: GlobalFloatPoolManifestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalFloatPoolManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedGlobalFloatPoolManifestAdjuster: GlobalFloatPoolManifestAdjuster {
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

        func adjust(_ item: GlobalFloatPoolManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentGlobalFloatPoolManifestAdjuster: GlobalFloatPoolManifestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalFloatPoolManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global float pool manifest steps in order and keeps a trace of each.
    final class GlobalFloatPoolManifestEngine {
        var steps: [any GlobalFloatPoolManifestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalFloatPoolManifestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalFloatPoolManifest) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [GlobalFloatPoolManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalFloatPoolManifestEngine(_ flags: Kit.Flags.Registry) -> GlobalFloatPoolManifestEngine {
        return GlobalFloatPoolManifestEngine(
            steps: [
                RoundingGlobalFloatPoolManifestAdjuster(step: 0.25),
                MinimumGlobalFloatPoolManifestAdjuster(minimum: 33.1),
                TitleGlobalFloatPoolManifestAdjuster(factors: ["central": 0.84, "west": 1.36]),
                CapGlobalFloatPoolManifestAdjuster(cap: 17977.0),
                FlaggedGlobalFloatPoolManifestAdjuster(
                    flags: flags,
                    flag: "global-float-pool-manifest-default",
                    percent: -7.4
                ),
                PercentGlobalFloatPoolManifestAdjuster(percent: -4.3),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 22455.3
        )
    }
}
