import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the read manifest calculation.
    protocol ReadManifestStep {
        func describe() -> String
        func adjust(_ item: ReadManifest, value: Double) -> Double
    }

    final class CapReadManifestAdjuster: ReadManifestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReadManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedReadManifestAdjuster: ReadManifestStep {
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

        func adjust(_ item: ReadManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ReadManifestSequenceOffsetAdjuster: ReadManifestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: ReadManifest, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class RoundingReadManifestAdjuster: ReadManifestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReadManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentReadManifestAdjuster: ReadManifestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReadManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the read manifest steps in order and keeps a trace of each.
    final class ReadManifestEngine {
        var steps: [any ReadManifestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReadManifestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ReadManifest) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [ReadManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultReadManifestEngine(_ flags: Kit.Flags.Registry) -> ReadManifestEngine {
        return ReadManifestEngine(
            steps: [
                CapReadManifestAdjuster(cap: 40941.0),
                FlaggedReadManifestAdjuster(flags: flags, flag: "read-manifest-regional", percent: 8.7),
                ReadManifestSequenceOffsetAdjuster(weight: 1.84),
                RoundingReadManifestAdjuster(step: 0.5),
                PercentReadManifestAdjuster(percent: -20.0),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 44291.8
        )
    }
}
