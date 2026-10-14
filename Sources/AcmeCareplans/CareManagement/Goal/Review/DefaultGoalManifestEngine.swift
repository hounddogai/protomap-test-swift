import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the default goal manifest calculation.
    protocol DefaultGoalManifestAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultGoalManifest, value: Double) -> Double
    }

    final class PercentDefaultGoalManifestAdjuster: DefaultGoalManifestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultGoalManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapDefaultGoalManifestAdjuster: DefaultGoalManifestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultGoalManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedDefaultGoalManifestAdjuster: DefaultGoalManifestAdjuster {
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

        func adjust(_ item: DefaultGoalManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default goal manifest steps in order and keeps a trace of each.
    final class DefaultGoalManifestEngine {
        var steps: [any DefaultGoalManifestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultGoalManifestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultGoalManifest) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [DefaultGoalManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultGoalManifestEngine(_ flags: Kit.Flags.Registry) -> DefaultGoalManifestEngine {
        return DefaultGoalManifestEngine(
            steps: [
                PercentDefaultGoalManifestAdjuster(percent: -10.1),
                CapDefaultGoalManifestAdjuster(cap: 12630.0),
                FlaggedDefaultGoalManifestAdjuster(
                    flags: flags,
                    flag: "default-goal-manifest-regional",
                    percent: -3.4
                ),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 71956.5
        )
    }
}
