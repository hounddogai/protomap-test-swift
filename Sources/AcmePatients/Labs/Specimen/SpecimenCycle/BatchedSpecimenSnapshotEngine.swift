import AcmePlatform
import Foundation

extension Labs {
    /// One step of the batched specimen snapshot calculation.
    protocol BatchedSpecimenSnapshotStep {
        func describe() -> String
        func adjust(_ item: BatchedSpecimenSnapshot, value: Double) -> Double
    }

    final class FlaggedBatchedSpecimenSnapshotAdjuster: BatchedSpecimenSnapshotStep {
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

        func adjust(_ item: BatchedSpecimenSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class BatchedSpecimenSnapshotCopayOffsetAdjuster: BatchedSpecimenSnapshotStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: BatchedSpecimenSnapshot, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class TieredBatchedSpecimenSnapshotAdjuster: BatchedSpecimenSnapshotStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedSpecimenSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the batched specimen snapshot steps in order and keeps a trace of each.
    final class BatchedSpecimenSnapshotEngine {
        var steps: [any BatchedSpecimenSnapshotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedSpecimenSnapshotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BatchedSpecimenSnapshot) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [BatchedSpecimenSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBatchedSpecimenSnapshotEngine(_ flags: Kit.Flags.Registry) -> BatchedSpecimenSnapshotEngine {
        return BatchedSpecimenSnapshotEngine(
            steps: [
                FlaggedBatchedSpecimenSnapshotAdjuster(
                    flags: flags,
                    flag: "batched-specimen-snapshot-fallback",
                    percent: 3.0
                ),
                BatchedSpecimenSnapshotCopayOffsetAdjuster(weight: 1.81),
                TieredBatchedSpecimenSnapshotAdjuster(
                    bounds: [214.0, 4590.0, 8099.0, 8120.0],
                    rates: [0.9, 0.82, 1.0, 0.99]
                ),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 78285.9
        )
    }
}
