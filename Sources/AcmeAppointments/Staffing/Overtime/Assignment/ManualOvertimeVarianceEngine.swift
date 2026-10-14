import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the manual overtime variance calculation.
    protocol ManualOvertimeVarianceAdjuster {
        func describe() -> String
        func adjust(_ item: ManualOvertimeVariance, value: Double) -> Double
    }

    final class CapManualOvertimeVarianceAdjuster: ManualOvertimeVarianceAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualOvertimeVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedManualOvertimeVarianceAdjuster: ManualOvertimeVarianceAdjuster {
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

        func adjust(_ item: ManualOvertimeVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumManualOvertimeVarianceAdjuster: ManualOvertimeVarianceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualOvertimeVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingManualOvertimeVarianceAdjuster: ManualOvertimeVarianceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualOvertimeVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredManualOvertimeVarianceAdjuster: ManualOvertimeVarianceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualOvertimeVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the manual overtime variance steps in order and keeps a trace of each.
    final class ManualOvertimeVarianceEngine {
        var steps: [any ManualOvertimeVarianceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualOvertimeVarianceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualOvertimeVariance) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [ManualOvertimeVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualOvertimeVarianceEngine(_ flags: Kit.Flags.Registry) -> ManualOvertimeVarianceEngine {
        return ManualOvertimeVarianceEngine(
            steps: [
                CapManualOvertimeVarianceAdjuster(cap: 47491.0),
                FlaggedManualOvertimeVarianceAdjuster(
                    flags: flags,
                    flag: "manual-overtime-variance-scheduled",
                    percent: -7.4
                ),
                MinimumManualOvertimeVarianceAdjuster(minimum: 35.3),
                RoundingManualOvertimeVarianceAdjuster(step: 0.1),
                TieredManualOvertimeVarianceAdjuster(
                    bounds: [3967.0, 6165.0, 6508.0, 9225.0],
                    rates: [0.84, 0.82, 1.1, 1.13]
                ),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 11003.7
        )
    }
}
