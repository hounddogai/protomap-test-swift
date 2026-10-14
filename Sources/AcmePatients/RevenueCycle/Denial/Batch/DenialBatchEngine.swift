import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial batch calculation.
    protocol DenialBatchStep {
        func describe() -> String
        func adjust(_ item: DenialBatch, value: Double) -> Double
    }

    final class RoundingDenialBatchAdjuster: DenialBatchStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DenialBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedDenialBatchAdjuster: DenialBatchStep {
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

        func adjust(_ item: DenialBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapDenialBatchAdjuster: DenialBatchStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DenialBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class DenialBatchQuantityOffsetAdjuster: DenialBatchStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: DenialBatch, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class SourceDenialBatchAdjuster: DenialBatchStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: DenialBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredDenialBatchAdjuster: DenialBatchStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DenialBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the denial batch steps in order and keeps a trace of each.
    final class DenialBatchEngine {
        var steps: [any DenialBatchStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialBatchStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DenialBatch) -> Double {
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

        func evaluateAll(_ items: [DenialBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDenialBatchEngine(_ flags: Kit.Flags.Registry) -> DenialBatchEngine {
        return DenialBatchEngine(
            steps: [
                RoundingDenialBatchAdjuster(step: 1.0),
                FlaggedDenialBatchAdjuster(flags: flags, flag: "denial-batch-global", percent: 5.0),
                CapDenialBatchAdjuster(cap: 2231.0),
                DenialBatchQuantityOffsetAdjuster(weight: 0.42),
                SourceDenialBatchAdjuster(factors: ["retail": 0.72, "west": 1.38]),
                TieredDenialBatchAdjuster(bounds: [1088.0, 1515.0, 4375.0, 8593.0], rates: [1.04, 1.01, 0.99, 0.91]),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 62861.8
        )
    }
}
