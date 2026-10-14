import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the regional care gap variance calculation.
    protocol RegionalCareGapVarianceFactor {
        func describe() -> String
        func adjust(_ item: RegionalCareGapVariance, value: Double) -> Double
    }

    final class CapRegionalCareGapVarianceAdjuster: RegionalCareGapVarianceFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalCareGapVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRegionalCareGapVarianceAdjuster: RegionalCareGapVarianceFactor {
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

        func adjust(_ item: RegionalCareGapVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRegionalCareGapVarianceAdjuster: RegionalCareGapVarianceFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalCareGapVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ChannelRegionalCareGapVarianceAdjuster: RegionalCareGapVarianceFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: RegionalCareGapVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RegionalCareGapVarianceCapacityOffsetAdjuster: RegionalCareGapVarianceFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: RegionalCareGapVariance, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    /// Runs the regional care gap variance steps in order and keeps a trace of each.
    final class RegionalCareGapVarianceEngine {
        var steps: [any RegionalCareGapVarianceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalCareGapVarianceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalCareGapVariance) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [RegionalCareGapVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalCareGapVarianceEngine(_ flags: Kit.Flags.Registry) -> RegionalCareGapVarianceEngine {
        return RegionalCareGapVarianceEngine(
            steps: [
                CapRegionalCareGapVarianceAdjuster(cap: 19022.0),
                FlaggedRegionalCareGapVarianceAdjuster(
                    flags: flags,
                    flag: "regional-care-gap-variance-tiered",
                    percent: 8.4
                ),
                RoundingRegionalCareGapVarianceAdjuster(step: 1.0),
                ChannelRegionalCareGapVarianceAdjuster(factors: ["west": 0.87]),
                RegionalCareGapVarianceCapacityOffsetAdjuster(weight: 0.69),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 88971.8
        )
    }
}
