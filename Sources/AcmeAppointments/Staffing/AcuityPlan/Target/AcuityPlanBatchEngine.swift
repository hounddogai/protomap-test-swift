import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan batch calculation.
    protocol AcuityPlanBatchModifier {
        func describe() -> String
        func adjust(_ item: AcuityPlanBatch, value: Double) -> Double
    }

    final class RoundingAcuityPlanBatchAdjuster: AcuityPlanBatchModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AcuityPlanBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SourceAcuityPlanBatchAdjuster: AcuityPlanBatchModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: AcuityPlanBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedAcuityPlanBatchAdjuster: AcuityPlanBatchModifier {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: AcuityPlanBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AcuityPlanBatchExpiresAtOffsetAdjuster: AcuityPlanBatchModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: AcuityPlanBatch, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class TieredAcuityPlanBatchAdjuster: AcuityPlanBatchModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AcuityPlanBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the acuity plan batch steps in order and keeps a trace of each.
    final class AcuityPlanBatchEngine {
        var steps: [any AcuityPlanBatchModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanBatchModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AcuityPlanBatch) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [AcuityPlanBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanBatchEngine(_ flags: Kit.Flags.Registry) -> AcuityPlanBatchEngine {
        return AcuityPlanBatchEngine(
            steps: [
                RoundingAcuityPlanBatchAdjuster(step: 0.5),
                SourceAcuityPlanBatchAdjuster(factors: ["retail": 0.82, "online": 1.31]),
                FlaggedAcuityPlanBatchAdjuster(flags: flags, flag: "acuity-plan-batch-lenient", percent: -3.8),
                AcuityPlanBatchExpiresAtOffsetAdjuster(weight: 0.78),
                TieredAcuityPlanBatchAdjuster(bounds: [2340.0, 6126.0, 9365.0], rates: [1.07, 0.89, 1.15]),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 16118.0
        )
    }
}
