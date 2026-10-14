import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the legacy acuity plan policy calculation.
    protocol LegacyAcuityPlanPolicyFactor {
        func describe() -> String
        func adjust(_ item: LegacyAcuityPlanPolicy, value: Double) -> Double
    }

    final class LegacyAcuityPlanPolicyMinimumOffsetAdjuster: LegacyAcuityPlanPolicyFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: LegacyAcuityPlanPolicy, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class TieredLegacyAcuityPlanPolicyAdjuster: LegacyAcuityPlanPolicyFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyAcuityPlanPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumLegacyAcuityPlanPolicyAdjuster: LegacyAcuityPlanPolicyFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyAcuityPlanPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the legacy acuity plan policy steps in order and keeps a trace of each.
    final class LegacyAcuityPlanPolicyEngine {
        var steps: [any LegacyAcuityPlanPolicyFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyAcuityPlanPolicyFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyAcuityPlanPolicy) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyAcuityPlanPolicyFactor = steps[index]
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

        func evaluateAll(_ items: [LegacyAcuityPlanPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyAcuityPlanPolicyEngine() -> LegacyAcuityPlanPolicyEngine {
        return LegacyAcuityPlanPolicyEngine(
            steps: [
                LegacyAcuityPlanPolicyMinimumOffsetAdjuster(weight: 1.05),
                TieredLegacyAcuityPlanPolicyAdjuster(bounds: [1797.0, 3198.0], rates: [1.07, 1.18]),
                MinimumLegacyAcuityPlanPolicyAdjuster(minimum: 4.1),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 42481.7
        )
    }
}
