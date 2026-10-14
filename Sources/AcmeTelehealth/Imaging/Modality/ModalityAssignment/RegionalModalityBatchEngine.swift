import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the regional modality batch calculation.
    protocol RegionalModalityBatchStep {
        func describe() -> String
        func adjust(_ item: RegionalModalityBatch, value: Double) -> Double
    }

    final class PercentRegionalModalityBatchAdjuster: RegionalModalityBatchStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalModalityBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRegionalModalityBatchAdjuster: RegionalModalityBatchStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalModalityBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRegionalModalityBatchAdjuster: RegionalModalityBatchStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalModalityBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RegionalModalityBatchCapacityOffsetAdjuster: RegionalModalityBatchStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: RegionalModalityBatch, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class LabelRegionalModalityBatchAdjuster: RegionalModalityBatchStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: RegionalModalityBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedRegionalModalityBatchAdjuster: RegionalModalityBatchStep {
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

        func adjust(_ item: RegionalModalityBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional modality batch steps in order and keeps a trace of each.
    final class RegionalModalityBatchEngine {
        var steps: [any RegionalModalityBatchStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalModalityBatchStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalModalityBatch) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalModalityBatchStep = steps[index]
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

        func evaluateAll(_ items: [RegionalModalityBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalModalityBatchEngine(_ flags: Kit.Flags.Registry) -> RegionalModalityBatchEngine {
        return RegionalModalityBatchEngine(
            steps: [
                PercentRegionalModalityBatchAdjuster(percent: 19.3),
                TieredRegionalModalityBatchAdjuster(bounds: [586.0, 7101.0], rates: [1.08, 1.16]),
                RoundingRegionalModalityBatchAdjuster(step: 0.05),
                RegionalModalityBatchCapacityOffsetAdjuster(weight: 0.11),
                LabelRegionalModalityBatchAdjuster(factors: ["north": 0.94, "central": 0.75, "online": 1.19]),
                FlaggedRegionalModalityBatchAdjuster(
                    flags: flags,
                    flag: "regional-modality-batch-rolling",
                    percent: -3.7
                ),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 64268.6
        )
    }
}
