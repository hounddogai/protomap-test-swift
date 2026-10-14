import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure adjustment calculation.
    protocol ClosureAdjustmentAdjuster {
        func describe() -> String
        func adjust(_ item: ClosureAdjustment, value: Double) -> Double
    }

    final class MinimumClosureAdjustmentAdjuster: ClosureAdjustmentAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClosureAdjustment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingClosureAdjustmentAdjuster: ClosureAdjustmentAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClosureAdjustment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapClosureAdjustmentAdjuster: ClosureAdjustmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClosureAdjustment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredClosureAdjustmentAdjuster: ClosureAdjustmentAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClosureAdjustment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedClosureAdjustmentAdjuster: ClosureAdjustmentAdjuster {
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

        func adjust(_ item: ClosureAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentClosureAdjustmentAdjuster: ClosureAdjustmentAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClosureAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the closure adjustment steps in order and keeps a trace of each.
    final class ClosureAdjustmentEngine {
        var steps: [any ClosureAdjustmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosureAdjustmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ClosureAdjustment) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [ClosureAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultClosureAdjustmentEngine(_ flags: Kit.Flags.Registry) -> ClosureAdjustmentEngine {
        return ClosureAdjustmentEngine(
            steps: [
                MinimumClosureAdjustmentAdjuster(minimum: 23.1),
                RoundingClosureAdjustmentAdjuster(step: 0.25),
                CapClosureAdjustmentAdjuster(cap: 15781.0),
                TieredClosureAdjustmentAdjuster(bounds: [4336.0, 7950.0], rates: [1.0, 0.86]),
                FlaggedClosureAdjustmentAdjuster(flags: flags, flag: "closure-adjustment-legacy", percent: -6.0),
                PercentClosureAdjustmentAdjuster(percent: -21.2),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 51810.8
        )
    }
}
