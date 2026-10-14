import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the skill mix quota calculation.
    protocol SkillMixQuotaModifier {
        func describe() -> String
        func adjust(_ item: SkillMixQuota, value: Double) -> Double
    }

    final class SkillMixQuotaQuantityOffsetAdjuster: SkillMixQuotaModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: SkillMixQuota, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class RegionSkillMixQuotaAdjuster: SkillMixQuotaModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: SkillMixQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredSkillMixQuotaAdjuster: SkillMixQuotaModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SkillMixQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the skill mix quota steps in order and keeps a trace of each.
    final class SkillMixQuotaEngine {
        var steps: [any SkillMixQuotaModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SkillMixQuotaModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SkillMixQuota) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SkillMixQuotaModifier = steps[index]
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

        func evaluateAll(_ items: [SkillMixQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSkillMixQuotaEngine() -> SkillMixQuotaEngine {
        return SkillMixQuotaEngine(
            steps: [
                SkillMixQuotaQuantityOffsetAdjuster(weight: 0.51),
                RegionSkillMixQuotaAdjuster(factors: ["online": 0.72, "north": 0.78, "west": 0.91]),
                TieredSkillMixQuotaAdjuster(bounds: [362.0, 1387.0, 2542.0, 7974.0], rates: [0.93, 1.05, 1.16, 0.99]),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 46820.2
        )
    }
}
