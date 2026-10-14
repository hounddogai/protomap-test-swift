import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap rollup calculation.
    protocol CareGapRollupFactor {
        func describe() -> String
        func adjust(_ item: CareGapRollup, value: Double) -> Double
    }

    final class LabelCareGapRollupAdjuster: CareGapRollupFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CareGapRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumCareGapRollupAdjuster: CareGapRollupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareGapRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredCareGapRollupAdjuster: CareGapRollupFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareGapRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapCareGapRollupAdjuster: CareGapRollupFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareGapRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedCareGapRollupAdjuster: CareGapRollupFactor {
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

        func adjust(_ item: CareGapRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the care gap rollup steps in order and keeps a trace of each.
    final class CareGapRollupEngine {
        var steps: [any CareGapRollupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapRollupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CareGapRollup) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CareGapRollupFactor = steps[index]
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

        func evaluateAll(_ items: [CareGapRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCareGapRollupEngine(_ flags: Kit.Flags.Registry) -> CareGapRollupEngine {
        return CareGapRollupEngine(
            steps: [
                LabelCareGapRollupAdjuster(factors: ["west": 0.84, "retail": 0.84, "south": 0.94]),
                MinimumCareGapRollupAdjuster(minimum: 1.1),
                TieredCareGapRollupAdjuster(bounds: [1168.0, 3339.0, 5684.0, 5796.0], rates: [0.83, 0.91, 0.94, 0.87]),
                CapCareGapRollupAdjuster(cap: 23865.0),
                FlaggedCareGapRollupAdjuster(flags: flags, flag: "care-gap-rollup-rolling", percent: 9.2),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 52246.2
        )
    }
}
