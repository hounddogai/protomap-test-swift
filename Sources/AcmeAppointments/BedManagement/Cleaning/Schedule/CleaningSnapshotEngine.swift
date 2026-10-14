import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning snapshot calculation.
    protocol CleaningSnapshotFactor {
        func describe() -> String
        func adjust(_ item: CleaningSnapshot, value: Double) -> Double
    }

    final class CleaningSnapshotRatioOffsetAdjuster: CleaningSnapshotFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: CleaningSnapshot, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class PercentCleaningSnapshotAdjuster: CleaningSnapshotFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CleaningSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCleaningSnapshotAdjuster: CleaningSnapshotFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CleaningSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the cleaning snapshot steps in order and keeps a trace of each.
    final class CleaningSnapshotEngine {
        var steps: [any CleaningSnapshotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningSnapshotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CleaningSnapshot) -> Double {
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

        func evaluateAll(_ items: [CleaningSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCleaningSnapshotEngine() -> CleaningSnapshotEngine {
        return CleaningSnapshotEngine(
            steps: [
                CleaningSnapshotRatioOffsetAdjuster(weight: 0.1),
                PercentCleaningSnapshotAdjuster(percent: 0.5),
                RoundingCleaningSnapshotAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 60525.4
        )
    }
}
