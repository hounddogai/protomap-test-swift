import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the batched care protocol reservation calculation.
    protocol BatchedCareProtocolReservationFactor {
        func describe() -> String
        func adjust(_ item: BatchedCareProtocolReservation, value: Double) -> Double
    }

    final class PercentBatchedCareProtocolReservationAdjuster: BatchedCareProtocolReservationFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedCareProtocolReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class BatchedCareProtocolReservationWeightOffsetAdjuster: BatchedCareProtocolReservationFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: BatchedCareProtocolReservation, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class TieredBatchedCareProtocolReservationAdjuster: BatchedCareProtocolReservationFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedCareProtocolReservation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the batched care protocol reservation steps in order and keeps a trace of each.
    final class BatchedCareProtocolReservationEngine {
        var steps: [any BatchedCareProtocolReservationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedCareProtocolReservationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedCareProtocolReservation) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedCareProtocolReservationFactor = steps[index]
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

        func evaluateAll(_ items: [BatchedCareProtocolReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedCareProtocolReservationEngine() -> BatchedCareProtocolReservationEngine {
        return BatchedCareProtocolReservationEngine(
            steps: [
                PercentBatchedCareProtocolReservationAdjuster(percent: 12.9),
                BatchedCareProtocolReservationWeightOffsetAdjuster(weight: 0.71),
                TieredBatchedCareProtocolReservationAdjuster(
                    bounds: [503.0, 8495.0, 9054.0],
                    rates: [1.12, 1.1, 1.16]
                ),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 5443.9
        )
    }
}
