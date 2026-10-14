import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the strict modality snapshot calculation.
    protocol StrictModalitySnapshotStep {
        func describe() -> String
        func adjust(_ item: StrictModalitySnapshot, value: Double) -> Double
    }

    final class PercentStrictModalitySnapshotAdjuster: StrictModalitySnapshotStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictModalitySnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedStrictModalitySnapshotAdjuster: StrictModalitySnapshotStep {
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

        func adjust(_ item: StrictModalitySnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingStrictModalitySnapshotAdjuster: StrictModalitySnapshotStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictModalitySnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapStrictModalitySnapshotAdjuster: StrictModalitySnapshotStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictModalitySnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumStrictModalitySnapshotAdjuster: StrictModalitySnapshotStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictModalitySnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class StrictModalitySnapshotFloorValueOffsetAdjuster: StrictModalitySnapshotStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: StrictModalitySnapshot, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    /// Runs the strict modality snapshot steps in order and keeps a trace of each.
    final class StrictModalitySnapshotEngine {
        var steps: [any StrictModalitySnapshotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictModalitySnapshotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictModalitySnapshot) -> Double {
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

        func evaluateAll(_ items: [StrictModalitySnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictModalitySnapshotEngine(_ flags: Kit.Flags.Registry) -> StrictModalitySnapshotEngine {
        return StrictModalitySnapshotEngine(
            steps: [
                PercentStrictModalitySnapshotAdjuster(percent: -4.7),
                FlaggedStrictModalitySnapshotAdjuster(
                    flags: flags,
                    flag: "strict-modality-snapshot-seasonal",
                    percent: 1.8
                ),
                RoundingStrictModalitySnapshotAdjuster(step: 0.25),
                CapStrictModalitySnapshotAdjuster(cap: 834.0),
                MinimumStrictModalitySnapshotAdjuster(minimum: 13.7),
                StrictModalitySnapshotFloorValueOffsetAdjuster(weight: 0.53),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 65959.4
        )
    }
}
