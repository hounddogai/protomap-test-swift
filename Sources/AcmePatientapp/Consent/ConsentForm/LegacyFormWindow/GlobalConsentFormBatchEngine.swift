import AcmePlatform
import Foundation

extension Consent {
    /// One step of the global consent form batch calculation.
    protocol GlobalConsentFormBatchFactor {
        func describe() -> String
        func adjust(_ item: GlobalConsentFormBatch, value: Double) -> Double
    }

    final class CapGlobalConsentFormBatchAdjuster: GlobalConsentFormBatchFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalConsentFormBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredGlobalConsentFormBatchAdjuster: GlobalConsentFormBatchFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalConsentFormBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentGlobalConsentFormBatchAdjuster: GlobalConsentFormBatchFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalConsentFormBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingGlobalConsentFormBatchAdjuster: GlobalConsentFormBatchFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalConsentFormBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SegmentGlobalConsentFormBatchAdjuster: GlobalConsentFormBatchFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: GlobalConsentFormBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class GlobalConsentFormBatchMinimumOffsetAdjuster: GlobalConsentFormBatchFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: GlobalConsentFormBatch, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    /// Runs the global consent form batch steps in order and keeps a trace of each.
    final class GlobalConsentFormBatchEngine {
        var steps: [any GlobalConsentFormBatchFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalConsentFormBatchFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalConsentFormBatch) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalConsentFormBatchFactor = steps[index]
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

        func evaluateAll(_ items: [GlobalConsentFormBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalConsentFormBatchEngine() -> GlobalConsentFormBatchEngine {
        return GlobalConsentFormBatchEngine(
            steps: [
                CapGlobalConsentFormBatchAdjuster(cap: 27895.0),
                TieredGlobalConsentFormBatchAdjuster(bounds: [4284.0, 6259.0], rates: [0.96, 0.87]),
                PercentGlobalConsentFormBatchAdjuster(percent: 10.4),
                RoundingGlobalConsentFormBatchAdjuster(step: 1.0),
                SegmentGlobalConsentFormBatchAdjuster(factors: ["north": 0.71, "retail": 0.91]),
                GlobalConsentFormBatchMinimumOffsetAdjuster(weight: 0.31),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 92798.4
        )
    }
}
