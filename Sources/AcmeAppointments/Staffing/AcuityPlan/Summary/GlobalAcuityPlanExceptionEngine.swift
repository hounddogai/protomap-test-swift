import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the global acuity plan exception calculation.
    protocol GlobalAcuityPlanExceptionModifier {
        func describe() -> String
        func adjust(_ item: GlobalAcuityPlanException, value: Double) -> Double
    }

    final class TitleGlobalAcuityPlanExceptionAdjuster: GlobalAcuityPlanExceptionModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: GlobalAcuityPlanException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumGlobalAcuityPlanExceptionAdjuster: GlobalAcuityPlanExceptionModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalAcuityPlanException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredGlobalAcuityPlanExceptionAdjuster: GlobalAcuityPlanExceptionModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalAcuityPlanException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentGlobalAcuityPlanExceptionAdjuster: GlobalAcuityPlanExceptionModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalAcuityPlanException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global acuity plan exception steps in order and keeps a trace of each.
    final class GlobalAcuityPlanExceptionEngine {
        var steps: [any GlobalAcuityPlanExceptionModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalAcuityPlanExceptionModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalAcuityPlanException) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalAcuityPlanExceptionModifier = steps[index]
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

        func evaluateAll(_ items: [GlobalAcuityPlanException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalAcuityPlanExceptionEngine() -> GlobalAcuityPlanExceptionEngine {
        return GlobalAcuityPlanExceptionEngine(
            steps: [
                TitleGlobalAcuityPlanExceptionAdjuster(factors: ["retail": 0.95, "east": 1.15]),
                MinimumGlobalAcuityPlanExceptionAdjuster(minimum: 10.4),
                TieredGlobalAcuityPlanExceptionAdjuster(bounds: [7071.0, 7095.0], rates: [0.96, 1.08]),
                PercentGlobalAcuityPlanExceptionAdjuster(percent: 19.2),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 16833.9
        )
    }
}
