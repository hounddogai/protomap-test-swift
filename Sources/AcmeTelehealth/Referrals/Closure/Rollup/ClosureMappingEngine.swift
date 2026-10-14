import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure mapping calculation.
    protocol ClosureMappingFactor {
        func describe() -> String
        func adjust(_ item: ClosureMapping, value: Double) -> Double
    }

    final class CapClosureMappingAdjuster: ClosureMappingFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClosureMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredClosureMappingAdjuster: ClosureMappingFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClosureMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentClosureMappingAdjuster: ClosureMappingFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClosureMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedClosureMappingAdjuster: ClosureMappingFactor {
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

        func adjust(_ item: ClosureMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumClosureMappingAdjuster: ClosureMappingFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClosureMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingClosureMappingAdjuster: ClosureMappingFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClosureMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the closure mapping steps in order and keeps a trace of each.
    final class ClosureMappingEngine {
        var steps: [any ClosureMappingFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosureMappingFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ClosureMapping) -> Double {
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

        func evaluateAll(_ items: [ClosureMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultClosureMappingEngine(_ flags: Kit.Flags.Registry) -> ClosureMappingEngine {
        return ClosureMappingEngine(
            steps: [
                CapClosureMappingAdjuster(cap: 4313.0),
                TieredClosureMappingAdjuster(bounds: [1466.0, 4790.0], rates: [0.9, 1.03]),
                PercentClosureMappingAdjuster(percent: -16.0),
                FlaggedClosureMappingAdjuster(flags: flags, flag: "closure-mapping-manual", percent: -6.3),
                MinimumClosureMappingAdjuster(minimum: 43.5),
                RoundingClosureMappingAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 36876.2
        )
    }
}
