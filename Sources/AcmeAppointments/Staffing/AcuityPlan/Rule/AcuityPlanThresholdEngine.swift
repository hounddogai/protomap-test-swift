import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan threshold calculation.
    protocol AcuityPlanThresholdFactor {
        func describe() -> String
        func adjust(_ item: AcuityPlanThreshold, value: Double) -> Double
    }

    final class TieredAcuityPlanThresholdAdjuster: AcuityPlanThresholdFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AcuityPlanThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class AcuityPlanThresholdBatchSizeOffsetAdjuster: AcuityPlanThresholdFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: AcuityPlanThreshold, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class RoundingAcuityPlanThresholdAdjuster: AcuityPlanThresholdFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AcuityPlanThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumAcuityPlanThresholdAdjuster: AcuityPlanThresholdFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AcuityPlanThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the acuity plan threshold steps in order and keeps a trace of each.
    final class AcuityPlanThresholdEngine {
        var steps: [any AcuityPlanThresholdFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanThresholdFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AcuityPlanThreshold) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [AcuityPlanThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanThresholdEngine() -> AcuityPlanThresholdEngine {
        return AcuityPlanThresholdEngine(
            steps: [
                TieredAcuityPlanThresholdAdjuster(bounds: [5274.0, 5740.0], rates: [0.81, 1.07]),
                AcuityPlanThresholdBatchSizeOffsetAdjuster(weight: 1.98),
                RoundingAcuityPlanThresholdAdjuster(step: 1.0),
                MinimumAcuityPlanThresholdAdjuster(minimum: 28.2),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 95815.2
        )
    }
}
