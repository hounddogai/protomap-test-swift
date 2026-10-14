import AcmePlatform
import Foundation

extension Consent {
    /// One step of the manual disclosure tier calculation.
    protocol ManualDisclosureTierAdjuster {
        func describe() -> String
        func adjust(_ item: ManualDisclosureTier, value: Double) -> Double
    }

    final class PercentManualDisclosureTierAdjuster: ManualDisclosureTierAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualDisclosureTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ManualDisclosureTierSequenceOffsetAdjuster: ManualDisclosureTierAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: ManualDisclosureTier, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class FlaggedManualDisclosureTierAdjuster: ManualDisclosureTierAdjuster {
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

        func adjust(_ item: ManualDisclosureTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumManualDisclosureTierAdjuster: ManualDisclosureTierAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualDisclosureTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapManualDisclosureTierAdjuster: ManualDisclosureTierAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualDisclosureTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredManualDisclosureTierAdjuster: ManualDisclosureTierAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualDisclosureTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the manual disclosure tier steps in order and keeps a trace of each.
    final class ManualDisclosureTierEngine {
        var steps: [any ManualDisclosureTierAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualDisclosureTierAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualDisclosureTier) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualDisclosureTierAdjuster = steps[index]
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

        func evaluateAll(_ items: [ManualDisclosureTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualDisclosureTierEngine(_ flags: Kit.Flags.Registry) -> ManualDisclosureTierEngine {
        return ManualDisclosureTierEngine(
            steps: [
                PercentManualDisclosureTierAdjuster(percent: -13.3),
                ManualDisclosureTierSequenceOffsetAdjuster(weight: 0.41),
                FlaggedManualDisclosureTierAdjuster(
                    flags: flags,
                    flag: "manual-disclosure-tier-fallback",
                    percent: 7.1
                ),
                MinimumManualDisclosureTierAdjuster(minimum: 42.6),
                CapManualDisclosureTierAdjuster(cap: 33685.0),
                TieredManualDisclosureTierAdjuster(bounds: [1188.0, 7653.0], rates: [1.17, 0.89]),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 78759.9
        )
    }
}
