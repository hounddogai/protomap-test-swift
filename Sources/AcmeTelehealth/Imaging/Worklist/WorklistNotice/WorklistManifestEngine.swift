import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the worklist manifest calculation.
    protocol WorklistManifestAdjuster {
        func describe() -> String
        func adjust(_ item: WorklistManifest, value: Double) -> Double
    }

    final class WorklistManifestEndsAtOffsetAdjuster: WorklistManifestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: WorklistManifest, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class FlaggedWorklistManifestAdjuster: WorklistManifestAdjuster {
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

        func adjust(_ item: WorklistManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumWorklistManifestAdjuster: WorklistManifestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WorklistManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapWorklistManifestAdjuster: WorklistManifestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WorklistManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the worklist manifest steps in order and keeps a trace of each.
    final class WorklistManifestEngine {
        var steps: [any WorklistManifestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WorklistManifestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WorklistManifest) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [WorklistManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWorklistManifestEngine(_ flags: Kit.Flags.Registry) -> WorklistManifestEngine {
        return WorklistManifestEngine(
            steps: [
                WorklistManifestEndsAtOffsetAdjuster(weight: 1.01),
                FlaggedWorklistManifestAdjuster(flags: flags, flag: "worklist-manifest-primary", percent: 1.3),
                MinimumWorklistManifestAdjuster(minimum: 16.4),
                CapWorklistManifestAdjuster(cap: 15880.0),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 33024.2
        )
    }
}
