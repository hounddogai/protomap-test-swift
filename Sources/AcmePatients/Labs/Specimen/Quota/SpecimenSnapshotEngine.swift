import AcmePlatform
import Foundation

extension Labs {
    /// One step of the specimen snapshot calculation.
    protocol SpecimenSnapshotFactor {
        func describe() -> String
        func adjust(_ item: SpecimenSnapshot, value: Double) -> Double
    }

    final class MinimumSpecimenSnapshotAdjuster: SpecimenSnapshotFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SpecimenSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SpecimenSnapshotBatchSizeOffsetAdjuster: SpecimenSnapshotFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: SpecimenSnapshot, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class FlaggedSpecimenSnapshotAdjuster: SpecimenSnapshotFactor {
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

        func adjust(_ item: SpecimenSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the specimen snapshot steps in order and keeps a trace of each.
    final class SpecimenSnapshotEngine {
        var steps: [any SpecimenSnapshotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SpecimenSnapshotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SpecimenSnapshot) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [SpecimenSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSpecimenSnapshotEngine(_ flags: Kit.Flags.Registry) -> SpecimenSnapshotEngine {
        return SpecimenSnapshotEngine(
            steps: [
                MinimumSpecimenSnapshotAdjuster(minimum: 30.4),
                SpecimenSnapshotBatchSizeOffsetAdjuster(weight: 1.12),
                FlaggedSpecimenSnapshotAdjuster(flags: flags, flag: "specimen-snapshot-lenient", percent: 5.4),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 53276.3
        )
    }
}
