import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the manual care gap variance calculation.
    protocol ManualCareGapVarianceModifier {
        func describe() -> String
        func adjust(_ item: ManualCareGapVariance, value: Double) -> Double
    }

    final class ManualCareGapVarianceQuantityOffsetAdjuster: ManualCareGapVarianceModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: ManualCareGapVariance, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class PercentManualCareGapVarianceAdjuster: ManualCareGapVarianceModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualCareGapVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapManualCareGapVarianceAdjuster: ManualCareGapVarianceModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualCareGapVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumManualCareGapVarianceAdjuster: ManualCareGapVarianceModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualCareGapVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedManualCareGapVarianceAdjuster: ManualCareGapVarianceModifier {
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

        func adjust(_ item: ManualCareGapVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredManualCareGapVarianceAdjuster: ManualCareGapVarianceModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualCareGapVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the manual care gap variance steps in order and keeps a trace of each.
    final class ManualCareGapVarianceEngine {
        var steps: [any ManualCareGapVarianceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualCareGapVarianceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualCareGapVariance) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualCareGapVarianceModifier = steps[index]
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

        func evaluateAll(_ items: [ManualCareGapVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualCareGapVarianceEngine(_ flags: Kit.Flags.Registry) -> ManualCareGapVarianceEngine {
        return ManualCareGapVarianceEngine(
            steps: [
                ManualCareGapVarianceQuantityOffsetAdjuster(weight: 1.53),
                PercentManualCareGapVarianceAdjuster(percent: 21.3),
                CapManualCareGapVarianceAdjuster(cap: 24759.0),
                MinimumManualCareGapVarianceAdjuster(minimum: 9.7),
                FlaggedManualCareGapVarianceAdjuster(
                    flags: flags,
                    flag: "manual-care-gap-variance-tiered",
                    percent: -3.8
                ),
                TieredManualCareGapVarianceAdjuster(bounds: [302.0, 6265.0, 8115.0], rates: [1.11, 0.99, 0.83]),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 51018.8
        )
    }
}
