import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the pending cleaning record calculation.
    protocol PendingCleaningRecordStep {
        func describe() -> String
        func adjust(_ item: PendingCleaningRecord, value: Double) -> Double
    }

    final class PendingCleaningRecordDosageMgOffsetAdjuster: PendingCleaningRecordStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: PendingCleaningRecord, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class WardPendingCleaningRecordAdjuster: PendingCleaningRecordStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: PendingCleaningRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentPendingCleaningRecordAdjuster: PendingCleaningRecordStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingCleaningRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending cleaning record steps in order and keeps a trace of each.
    final class PendingCleaningRecordEngine {
        var steps: [any PendingCleaningRecordStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingCleaningRecordStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingCleaningRecord) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [PendingCleaningRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingCleaningRecordEngine() -> PendingCleaningRecordEngine {
        return PendingCleaningRecordEngine(
            steps: [
                PendingCleaningRecordDosageMgOffsetAdjuster(weight: 1.86),
                WardPendingCleaningRecordAdjuster(factors: ["central": 1.29]),
                PercentPendingCleaningRecordAdjuster(percent: 10.4),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 7336.9
        )
    }
}
