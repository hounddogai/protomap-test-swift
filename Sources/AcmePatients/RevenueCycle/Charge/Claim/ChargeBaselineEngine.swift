import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge baseline calculation.
    protocol ChargeBaselineAdjuster {
        func describe() -> String
        func adjust(_ item: ChargeBaseline, value: Double) -> Double
    }

    final class FlaggedChargeBaselineAdjuster: ChargeBaselineAdjuster {
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

        func adjust(_ item: ChargeBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChargeBaselineAttemptsOffsetAdjuster: ChargeBaselineAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: ChargeBaseline, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class TieredChargeBaselineAdjuster: ChargeBaselineAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ChargeBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentChargeBaselineAdjuster: ChargeBaselineAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ChargeBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapChargeBaselineAdjuster: ChargeBaselineAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ChargeBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the charge baseline steps in order and keeps a trace of each.
    final class ChargeBaselineEngine {
        var steps: [any ChargeBaselineAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeBaselineAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ChargeBaseline) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ChargeBaselineAdjuster = steps[index]
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

        func evaluateAll(_ items: [ChargeBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultChargeBaselineEngine(_ flags: Kit.Flags.Registry) -> ChargeBaselineEngine {
        return ChargeBaselineEngine(
            steps: [
                FlaggedChargeBaselineAdjuster(flags: flags, flag: "charge-baseline-legacy", percent: -5.6),
                ChargeBaselineAttemptsOffsetAdjuster(weight: 1.59),
                TieredChargeBaselineAdjuster(bounds: [5824.0, 9275.0], rates: [0.94, 1.0]),
                PercentChargeBaselineAdjuster(percent: 12.7),
                CapChargeBaselineAdjuster(cap: 19521.0),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 71646.5
        )
    }
}
