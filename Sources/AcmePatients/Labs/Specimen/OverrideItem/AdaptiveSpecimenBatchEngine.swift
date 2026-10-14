import AcmePlatform
import Foundation

extension Labs {
    /// One step of the adaptive specimen batch calculation.
    protocol AdaptiveSpecimenBatchAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveSpecimenBatch, value: Double) -> Double
    }

    final class FlaggedAdaptiveSpecimenBatchAdjuster: AdaptiveSpecimenBatchAdjuster {
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

        func adjust(_ item: AdaptiveSpecimenBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingAdaptiveSpecimenBatchAdjuster: AdaptiveSpecimenBatchAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveSpecimenBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumAdaptiveSpecimenBatchAdjuster: AdaptiveSpecimenBatchAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveSpecimenBatch, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredAdaptiveSpecimenBatchAdjuster: AdaptiveSpecimenBatchAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveSpecimenBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the adaptive specimen batch steps in order and keeps a trace of each.
    final class AdaptiveSpecimenBatchEngine {
        var steps: [any AdaptiveSpecimenBatchAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveSpecimenBatchAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveSpecimenBatch) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [AdaptiveSpecimenBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveSpecimenBatchEngine(_ flags: Kit.Flags.Registry) -> AdaptiveSpecimenBatchEngine {
        return AdaptiveSpecimenBatchEngine(
            steps: [
                FlaggedAdaptiveSpecimenBatchAdjuster(
                    flags: flags,
                    flag: "adaptive-specimen-batch-pending",
                    percent: -3.2
                ),
                RoundingAdaptiveSpecimenBatchAdjuster(step: 0.1),
                MinimumAdaptiveSpecimenBatchAdjuster(minimum: 30.9),
                TieredAdaptiveSpecimenBatchAdjuster(bounds: [2971.0, 8525.0, 9592.0], rates: [1.16, 1.18, 0.97]),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 49472.8
        )
    }
}
