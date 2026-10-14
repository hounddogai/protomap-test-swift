import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the transfer record calculation.
    protocol TransferRecordStep {
        func describe() -> String
        func adjust(_ item: TransferRecord, value: Double) -> Double
    }

    final class CategoryTransferRecordAdjuster: TransferRecordStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: TransferRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumTransferRecordAdjuster: TransferRecordStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TransferRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredTransferRecordAdjuster: TransferRecordStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TransferRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingTransferRecordAdjuster: TransferRecordStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TransferRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the transfer record steps in order and keeps a trace of each.
    final class TransferRecordEngine {
        var steps: [any TransferRecordStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TransferRecordStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TransferRecord) -> Double {
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

        func evaluateAll(_ items: [TransferRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTransferRecordEngine() -> TransferRecordEngine {
        return TransferRecordEngine(
            steps: [
                CategoryTransferRecordAdjuster(factors: ["retail": 0.92, "online": 0.86]),
                MinimumTransferRecordAdjuster(minimum: 44.2),
                TieredTransferRecordAdjuster(
                    bounds: [1760.0, 3708.0, 4955.0, 5241.0],
                    rates: [0.92, 1.17, 1.12, 0.97]
                ),
                RoundingTransferRecordAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 98510.8
        )
    }
}
