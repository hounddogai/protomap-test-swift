import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the rolling shift manifest calculation.
    protocol RollingShiftManifestFactor {
        func describe() -> String
        func adjust(_ item: RollingShiftManifest, value: Double) -> Double
    }

    final class RegionRollingShiftManifestAdjuster: RollingShiftManifestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: RollingShiftManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapRollingShiftManifestAdjuster: RollingShiftManifestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingShiftManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRollingShiftManifestAdjuster: RollingShiftManifestFactor {
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

        func adjust(_ item: RollingShiftManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRollingShiftManifestAdjuster: RollingShiftManifestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingShiftManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentRollingShiftManifestAdjuster: RollingShiftManifestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingShiftManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RollingShiftManifestRevisionOffsetAdjuster: RollingShiftManifestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: RollingShiftManifest, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    /// Runs the rolling shift manifest steps in order and keeps a trace of each.
    final class RollingShiftManifestEngine {
        var steps: [any RollingShiftManifestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingShiftManifestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingShiftManifest) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingShiftManifestFactor = steps[index]
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

        func evaluateAll(_ items: [RollingShiftManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingShiftManifestEngine(_ flags: Kit.Flags.Registry) -> RollingShiftManifestEngine {
        return RollingShiftManifestEngine(
            steps: [
                RegionRollingShiftManifestAdjuster(factors: ["retail": 1.21, "west": 1.1, "central": 0.81]),
                CapRollingShiftManifestAdjuster(cap: 18467.0),
                FlaggedRollingShiftManifestAdjuster(
                    flags: flags,
                    flag: "rolling-shift-manifest-primary",
                    percent: 5.4
                ),
                RoundingRollingShiftManifestAdjuster(step: 0.05),
                PercentRollingShiftManifestAdjuster(percent: 8.5),
                RollingShiftManifestRevisionOffsetAdjuster(weight: 1.93),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 48644.2
        )
    }
}
