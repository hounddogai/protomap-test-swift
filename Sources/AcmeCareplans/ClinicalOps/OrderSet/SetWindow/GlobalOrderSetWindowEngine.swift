import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the global order set window calculation.
    protocol GlobalOrderSetWindowAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalOrderSetWindow, value: Double) -> Double
    }

    final class SegmentGlobalOrderSetWindowAdjuster: GlobalOrderSetWindowAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: GlobalOrderSetWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumGlobalOrderSetWindowAdjuster: GlobalOrderSetWindowAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalOrderSetWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredGlobalOrderSetWindowAdjuster: GlobalOrderSetWindowAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalOrderSetWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapGlobalOrderSetWindowAdjuster: GlobalOrderSetWindowAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalOrderSetWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedGlobalOrderSetWindowAdjuster: GlobalOrderSetWindowAdjuster {
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

        func adjust(_ item: GlobalOrderSetWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class GlobalOrderSetWindowAttemptsOffsetAdjuster: GlobalOrderSetWindowAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: GlobalOrderSetWindow, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    /// Runs the global order set window steps in order and keeps a trace of each.
    final class GlobalOrderSetWindowEngine {
        var steps: [any GlobalOrderSetWindowAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalOrderSetWindowAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalOrderSetWindow) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [GlobalOrderSetWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalOrderSetWindowEngine(_ flags: Kit.Flags.Registry) -> GlobalOrderSetWindowEngine {
        return GlobalOrderSetWindowEngine(
            steps: [
                SegmentGlobalOrderSetWindowAdjuster(factors: ["east": 0.81, "central": 0.91, "retail": 0.84]),
                MinimumGlobalOrderSetWindowAdjuster(minimum: 4.9),
                TieredGlobalOrderSetWindowAdjuster(bounds: [6647.0, 8944.0, 9049.0], rates: [0.87, 1.05, 1.07]),
                CapGlobalOrderSetWindowAdjuster(cap: 27905.0),
                FlaggedGlobalOrderSetWindowAdjuster(
                    flags: flags,
                    flag: "global-order-set-window-scheduled",
                    percent: -5.4
                ),
                GlobalOrderSetWindowAttemptsOffsetAdjuster(weight: 0.3),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 5653.7
        )
    }
}
