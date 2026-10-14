import AcmePlatform
import Foundation

extension Consent {
    /// One step of the rolling witness manifest calculation.
    protocol RollingWitnessManifestFactor {
        func describe() -> String
        func adjust(_ item: RollingWitnessManifest, value: Double) -> Double
    }

    final class CapRollingWitnessManifestAdjuster: RollingWitnessManifestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingWitnessManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentRollingWitnessManifestAdjuster: RollingWitnessManifestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingWitnessManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRollingWitnessManifestAdjuster: RollingWitnessManifestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingWitnessManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedRollingWitnessManifestAdjuster: RollingWitnessManifestFactor {
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

        func adjust(_ item: RollingWitnessManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RollingWitnessManifestMarginOffsetAdjuster: RollingWitnessManifestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: RollingWitnessManifest, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class CategoryRollingWitnessManifestAdjuster: RollingWitnessManifestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: RollingWitnessManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the rolling witness manifest steps in order and keeps a trace of each.
    final class RollingWitnessManifestEngine {
        var steps: [any RollingWitnessManifestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingWitnessManifestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RollingWitnessManifest) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingWitnessManifestFactor = steps[index]
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

        func evaluateAll(_ items: [RollingWitnessManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRollingWitnessManifestEngine(_ flags: Kit.Flags.Registry) -> RollingWitnessManifestEngine {
        return RollingWitnessManifestEngine(
            steps: [
                CapRollingWitnessManifestAdjuster(cap: 27805.0),
                PercentRollingWitnessManifestAdjuster(percent: -16.7),
                MinimumRollingWitnessManifestAdjuster(minimum: 9.9),
                FlaggedRollingWitnessManifestAdjuster(
                    flags: flags,
                    flag: "rolling-witness-manifest-primary",
                    percent: -1.0
                ),
                RollingWitnessManifestMarginOffsetAdjuster(weight: 1.38),
                CategoryRollingWitnessManifestAdjuster(factors: ["retail": 0.89]),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 1227.9
        )
    }
}
