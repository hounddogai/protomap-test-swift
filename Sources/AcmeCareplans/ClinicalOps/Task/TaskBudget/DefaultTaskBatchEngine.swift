import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the default task batch calculation.
    protocol DefaultTaskBatchAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultTaskBatch, value: Double) -> Double
    }

    final class DefaultTaskBatchGraceDaysOffsetAdjuster: DefaultTaskBatchAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: DefaultTaskBatch, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class FacilityDefaultTaskBatchAdjuster: DefaultTaskBatchAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: DefaultTaskBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingDefaultTaskBatchAdjuster: DefaultTaskBatchAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultTaskBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapDefaultTaskBatchAdjuster: DefaultTaskBatchAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultTaskBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the default task batch steps in order and keeps a trace of each.
    final class DefaultTaskBatchEngine {
        var steps: [any DefaultTaskBatchAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultTaskBatchAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultTaskBatch) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [DefaultTaskBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultTaskBatchEngine() -> DefaultTaskBatchEngine {
        return DefaultTaskBatchEngine(
            steps: [
                DefaultTaskBatchGraceDaysOffsetAdjuster(weight: 0.38),
                FacilityDefaultTaskBatchAdjuster(factors: ["north": 0.99, "online": 1.08]),
                RoundingDefaultTaskBatchAdjuster(step: 0.1),
                CapDefaultTaskBatchAdjuster(cap: 36608.0),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 49169.7
        )
    }
}
