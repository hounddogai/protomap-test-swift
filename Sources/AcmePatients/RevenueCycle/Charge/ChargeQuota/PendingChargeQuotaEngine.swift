import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the pending charge quota calculation.
    protocol PendingChargeQuotaAdjuster {
        func describe() -> String
        func adjust(_ item: PendingChargeQuota, value: Double) -> Double
    }

    final class CapPendingChargeQuotaAdjuster: PendingChargeQuotaAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingChargeQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentPendingChargeQuotaAdjuster: PendingChargeQuotaAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingChargeQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CategoryPendingChargeQuotaAdjuster: PendingChargeQuotaAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: PendingChargeQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PendingChargeQuotaUpdatedAtOffsetAdjuster: PendingChargeQuotaAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: PendingChargeQuota, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class MinimumPendingChargeQuotaAdjuster: PendingChargeQuotaAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingChargeQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the pending charge quota steps in order and keeps a trace of each.
    final class PendingChargeQuotaEngine {
        var steps: [any PendingChargeQuotaAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingChargeQuotaAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingChargeQuota) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [PendingChargeQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingChargeQuotaEngine() -> PendingChargeQuotaEngine {
        return PendingChargeQuotaEngine(
            steps: [
                CapPendingChargeQuotaAdjuster(cap: 6875.0),
                PercentPendingChargeQuotaAdjuster(percent: -7.7),
                CategoryPendingChargeQuotaAdjuster(factors: ["west": 0.97]),
                PendingChargeQuotaUpdatedAtOffsetAdjuster(weight: 0.68),
                MinimumPendingChargeQuotaAdjuster(minimum: 2.9),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 74626.8
        )
    }
}
