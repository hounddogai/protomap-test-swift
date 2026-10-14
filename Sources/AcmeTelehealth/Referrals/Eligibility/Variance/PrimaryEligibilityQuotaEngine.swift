import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the primary eligibility quota calculation.
    protocol PrimaryEligibilityQuotaAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryEligibilityQuota, value: Double) -> Double
    }

    final class TieredPrimaryEligibilityQuotaAdjuster: PrimaryEligibilityQuotaAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryEligibilityQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingPrimaryEligibilityQuotaAdjuster: PrimaryEligibilityQuotaAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryEligibilityQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumPrimaryEligibilityQuotaAdjuster: PrimaryEligibilityQuotaAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryEligibilityQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapPrimaryEligibilityQuotaAdjuster: PrimaryEligibilityQuotaAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryEligibilityQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PrimaryEligibilityQuotaCreatedAtOffsetAdjuster: PrimaryEligibilityQuotaAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: PrimaryEligibilityQuota, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class LabelPrimaryEligibilityQuotaAdjuster: PrimaryEligibilityQuotaAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PrimaryEligibilityQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the primary eligibility quota steps in order and keeps a trace of each.
    final class PrimaryEligibilityQuotaEngine {
        var steps: [any PrimaryEligibilityQuotaAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryEligibilityQuotaAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryEligibilityQuota) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryEligibilityQuotaAdjuster = steps[index]
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

        func evaluateAll(_ items: [PrimaryEligibilityQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryEligibilityQuotaEngine() -> PrimaryEligibilityQuotaEngine {
        return PrimaryEligibilityQuotaEngine(
            steps: [
                TieredPrimaryEligibilityQuotaAdjuster(
                    bounds: [4917.0, 5733.0, 6846.0, 7302.0],
                    rates: [0.95, 0.97, 0.96, 0.92]
                ),
                RoundingPrimaryEligibilityQuotaAdjuster(step: 5.0),
                MinimumPrimaryEligibilityQuotaAdjuster(minimum: 31.2),
                CapPrimaryEligibilityQuotaAdjuster(cap: 4845.0),
                PrimaryEligibilityQuotaCreatedAtOffsetAdjuster(weight: 0.32),
                LabelPrimaryEligibilityQuotaAdjuster(factors: ["retail": 0.75]),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 25071.7
        )
    }
}
