import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the rolling inventory snapshot calculation.
    protocol RollingInventorySnapshotFactor {
        func describe() -> String
        func adjust(_ item: RollingInventorySnapshot, value: Double) -> Double
    }

    final class MinimumRollingInventorySnapshotAdjuster: RollingInventorySnapshotFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingInventorySnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingRollingInventorySnapshotAdjuster: RollingInventorySnapshotFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingInventorySnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRollingInventorySnapshotAdjuster: RollingInventorySnapshotFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingInventorySnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RollingInventorySnapshotDosageMgOffsetAdjuster: RollingInventorySnapshotFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: RollingInventorySnapshot, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class FacilityRollingInventorySnapshotAdjuster: RollingInventorySnapshotFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: RollingInventorySnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRollingInventorySnapshotAdjuster: RollingInventorySnapshotFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingInventorySnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rolling inventory snapshot steps in order and keeps a trace of each.
    final class RollingInventorySnapshotEngine {
        var steps: [any RollingInventorySnapshotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingInventorySnapshotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingInventorySnapshot) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingInventorySnapshotFactor = steps[index]
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

        func evaluateAll(_ items: [RollingInventorySnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingInventorySnapshotEngine() -> RollingInventorySnapshotEngine {
        return RollingInventorySnapshotEngine(
            steps: [
                MinimumRollingInventorySnapshotAdjuster(minimum: 37.6),
                RoundingRollingInventorySnapshotAdjuster(step: 0.25),
                CapRollingInventorySnapshotAdjuster(cap: 11018.0),
                RollingInventorySnapshotDosageMgOffsetAdjuster(weight: 0.2),
                FacilityRollingInventorySnapshotAdjuster(factors: ["north": 1.32]),
                PercentRollingInventorySnapshotAdjuster(percent: -16.3),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 25431.6
        )
    }
}
