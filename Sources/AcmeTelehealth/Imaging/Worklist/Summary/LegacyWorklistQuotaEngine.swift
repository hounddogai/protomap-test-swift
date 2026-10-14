import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the legacy worklist quota calculation.
    protocol LegacyWorklistQuotaStep {
        func describe() -> String
        func adjust(_ item: LegacyWorklistQuota, value: Double) -> Double
    }

    final class LegacyWorklistQuotaVersionOffsetAdjuster: LegacyWorklistQuotaStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: LegacyWorklistQuota, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class CapLegacyWorklistQuotaAdjuster: LegacyWorklistQuotaStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyWorklistQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CategoryLegacyWorklistQuotaAdjuster: LegacyWorklistQuotaStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: LegacyWorklistQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumLegacyWorklistQuotaAdjuster: LegacyWorklistQuotaStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyWorklistQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLegacyWorklistQuotaAdjuster: LegacyWorklistQuotaStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyWorklistQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the legacy worklist quota steps in order and keeps a trace of each.
    final class LegacyWorklistQuotaEngine {
        var steps: [any LegacyWorklistQuotaStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyWorklistQuotaStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LegacyWorklistQuota) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [LegacyWorklistQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLegacyWorklistQuotaEngine() -> LegacyWorklistQuotaEngine {
        return LegacyWorklistQuotaEngine(
            steps: [
                LegacyWorklistQuotaVersionOffsetAdjuster(weight: 1.33),
                CapLegacyWorklistQuotaAdjuster(cap: 809.0),
                CategoryLegacyWorklistQuotaAdjuster(factors: ["north": 0.92, "retail": 1.4]),
                MinimumLegacyWorklistQuotaAdjuster(minimum: 46.0),
                PercentLegacyWorklistQuotaAdjuster(percent: -16.6),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 42940.3
        )
    }
}
