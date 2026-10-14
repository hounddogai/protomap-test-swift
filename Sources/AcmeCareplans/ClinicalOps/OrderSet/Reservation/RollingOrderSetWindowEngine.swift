import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rolling order set window calculation.
    protocol RollingOrderSetWindowStep {
        func describe() -> String
        func adjust(_ item: RollingOrderSetWindow, value: Double) -> Double
    }

    final class RoundingRollingOrderSetWindowAdjuster: RollingOrderSetWindowStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingOrderSetWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRollingOrderSetWindowAdjuster: RollingOrderSetWindowStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingOrderSetWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CategoryRollingOrderSetWindowAdjuster: RollingOrderSetWindowStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: RollingOrderSetWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRollingOrderSetWindowAdjuster: RollingOrderSetWindowStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingOrderSetWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedRollingOrderSetWindowAdjuster: RollingOrderSetWindowStep {
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

        func adjust(_ item: RollingOrderSetWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRollingOrderSetWindowAdjuster: RollingOrderSetWindowStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingOrderSetWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the rolling order set window steps in order and keeps a trace of each.
    final class RollingOrderSetWindowEngine {
        var steps: [any RollingOrderSetWindowStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingOrderSetWindowStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingOrderSetWindow) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [RollingOrderSetWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingOrderSetWindowEngine(_ flags: Kit.Flags.Registry) -> RollingOrderSetWindowEngine {
        return RollingOrderSetWindowEngine(
            steps: [
                RoundingRollingOrderSetWindowAdjuster(step: 0.05),
                CapRollingOrderSetWindowAdjuster(cap: 3630.0),
                CategoryRollingOrderSetWindowAdjuster(factors: ["west": 1.17]),
                MinimumRollingOrderSetWindowAdjuster(minimum: 17.0),
                FlaggedRollingOrderSetWindowAdjuster(
                    flags: flags,
                    flag: "rolling-order-set-window-regional",
                    percent: 0.5
                ),
                TieredRollingOrderSetWindowAdjuster(bounds: [8394.0, 9578.0], rates: [0.98, 1.13]),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 74543.7
        )
    }
}
