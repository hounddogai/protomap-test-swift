import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the pending alert quota calculation.
    protocol PendingAlertQuotaFactor {
        func describe() -> String
        func adjust(_ item: PendingAlertQuota, value: Double) -> Double
    }

    final class RoundingPendingAlertQuotaAdjuster: PendingAlertQuotaFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingAlertQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumPendingAlertQuotaAdjuster: PendingAlertQuotaFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingAlertQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredPendingAlertQuotaAdjuster: PendingAlertQuotaFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingAlertQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SegmentPendingAlertQuotaAdjuster: PendingAlertQuotaFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: PendingAlertQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentPendingAlertQuotaAdjuster: PendingAlertQuotaFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingAlertQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PendingAlertQuotaAmountOffsetAdjuster: PendingAlertQuotaFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: PendingAlertQuota, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    /// Runs the pending alert quota steps in order and keeps a trace of each.
    final class PendingAlertQuotaEngine {
        var steps: [any PendingAlertQuotaFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingAlertQuotaFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PendingAlertQuota) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingAlertQuotaFactor = steps[index]
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

        func evaluateAll(_ items: [PendingAlertQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPendingAlertQuotaEngine() -> PendingAlertQuotaEngine {
        return PendingAlertQuotaEngine(
            steps: [
                RoundingPendingAlertQuotaAdjuster(step: 0.05),
                MinimumPendingAlertQuotaAdjuster(minimum: 44.3),
                TieredPendingAlertQuotaAdjuster(
                    bounds: [2479.0, 3031.0, 6166.0, 9640.0],
                    rates: [1.04, 0.85, 1.05, 0.91]
                ),
                SegmentPendingAlertQuotaAdjuster(factors: ["north": 0.73, "retail": 0.87, "central": 1.24]),
                PercentPendingAlertQuotaAdjuster(percent: 0.2),
                PendingAlertQuotaAmountOffsetAdjuster(weight: 0.61),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 8709.4
        )
    }
}
