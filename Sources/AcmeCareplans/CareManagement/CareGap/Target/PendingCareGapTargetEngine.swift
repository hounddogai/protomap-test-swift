import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the pending care gap target calculation.
    protocol PendingCareGapTargetAdjuster {
        func describe() -> String
        func adjust(_ item: PendingCareGapTarget, value: Double) -> Double
    }

    final class TieredPendingCareGapTargetAdjuster: PendingCareGapTargetAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingCareGapTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumPendingCareGapTargetAdjuster: PendingCareGapTargetAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingCareGapTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PendingCareGapTargetBatchSizeOffsetAdjuster: PendingCareGapTargetAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: PendingCareGapTarget, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class PercentPendingCareGapTargetAdjuster: PendingCareGapTargetAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingCareGapTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPendingCareGapTargetAdjuster: PendingCareGapTargetAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingCareGapTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelPendingCareGapTargetAdjuster: PendingCareGapTargetAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PendingCareGapTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the pending care gap target steps in order and keeps a trace of each.
    final class PendingCareGapTargetEngine {
        var steps: [any PendingCareGapTargetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingCareGapTargetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingCareGapTarget) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingCareGapTargetAdjuster = steps[index]
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

        func evaluateAll(_ items: [PendingCareGapTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingCareGapTargetEngine() -> PendingCareGapTargetEngine {
        return PendingCareGapTargetEngine(
            steps: [
                TieredPendingCareGapTargetAdjuster(
                    bounds: [964.0, 1570.0, 2572.0, 5878.0],
                    rates: [0.87, 0.95, 1.18, 0.84]
                ),
                MinimumPendingCareGapTargetAdjuster(minimum: 39.5),
                PendingCareGapTargetBatchSizeOffsetAdjuster(weight: 0.77),
                PercentPendingCareGapTargetAdjuster(percent: 2.3),
                CapPendingCareGapTargetAdjuster(cap: 40019.0),
                LabelPendingCareGapTargetAdjuster(factors: ["retail": 1.16, "north": 1.13, "west": 1.16]),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 89199.4
        )
    }
}
