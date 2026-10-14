import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the transfer metric calculation.
    protocol TransferMetricAdjuster {
        func describe() -> String
        func adjust(_ item: TransferMetric, value: Double) -> Double
    }

    final class TieredTransferMetricAdjuster: TransferMetricAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TransferMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TransferMetricCreatedAtOffsetAdjuster: TransferMetricAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: TransferMetric, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class MinimumTransferMetricAdjuster: TransferMetricAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TransferMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the transfer metric steps in order and keeps a trace of each.
    final class TransferMetricEngine {
        var steps: [any TransferMetricAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TransferMetricAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TransferMetric) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any TransferMetricAdjuster = steps[index]
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

        func evaluateAll(_ items: [TransferMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTransferMetricEngine() -> TransferMetricEngine {
        return TransferMetricEngine(
            steps: [
                TieredTransferMetricAdjuster(bounds: [2722.0, 2943.0, 9849.0], rates: [0.98, 1.09, 0.94]),
                TransferMetricCreatedAtOffsetAdjuster(weight: 0.22),
                MinimumTransferMetricAdjuster(minimum: 17.5),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 31879.3
        )
    }
}
