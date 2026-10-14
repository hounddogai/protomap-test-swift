import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan target calculation.
    protocol AcuityPlanTargetFactor {
        func describe() -> String
        func adjust(_ item: AcuityPlanTarget, value: Double) -> Double
    }

    final class TieredAcuityPlanTargetAdjuster: AcuityPlanTargetFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AcuityPlanTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentAcuityPlanTargetAdjuster: AcuityPlanTargetFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AcuityPlanTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingAcuityPlanTargetAdjuster: AcuityPlanTargetFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AcuityPlanTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapAcuityPlanTargetAdjuster: AcuityPlanTargetFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AcuityPlanTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SourceAcuityPlanTargetAdjuster: AcuityPlanTargetFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: AcuityPlanTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumAcuityPlanTargetAdjuster: AcuityPlanTargetFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AcuityPlanTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the acuity plan target steps in order and keeps a trace of each.
    final class AcuityPlanTargetEngine {
        var steps: [any AcuityPlanTargetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanTargetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AcuityPlanTarget) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AcuityPlanTargetFactor = steps[index]
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

        func evaluateAll(_ items: [AcuityPlanTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanTargetEngine() -> AcuityPlanTargetEngine {
        return AcuityPlanTargetEngine(
            steps: [
                TieredAcuityPlanTargetAdjuster(bounds: [1912.0, 3167.0, 6854.0], rates: [1.17, 0.87, 1.16]),
                PercentAcuityPlanTargetAdjuster(percent: 15.0),
                RoundingAcuityPlanTargetAdjuster(step: 0.05),
                CapAcuityPlanTargetAdjuster(cap: 29492.0),
                SourceAcuityPlanTargetAdjuster(factors: ["retail": 1.38, "south": 0.93]),
                MinimumAcuityPlanTargetAdjuster(minimum: 15.0),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 95377.5
        )
    }
}
