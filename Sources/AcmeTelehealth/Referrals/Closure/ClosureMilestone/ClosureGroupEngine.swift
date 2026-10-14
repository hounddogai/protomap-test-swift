import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure group calculation.
    protocol ClosureGroupAdjuster {
        func describe() -> String
        func adjust(_ item: ClosureGroup, value: Double) -> Double
    }

    final class ClosureGroupCostOffsetAdjuster: ClosureGroupAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: ClosureGroup, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class TieredClosureGroupAdjuster: ClosureGroupAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClosureGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FacilityClosureGroupAdjuster: ClosureGroupAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: ClosureGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedClosureGroupAdjuster: ClosureGroupAdjuster {
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

        func adjust(_ item: ClosureGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingClosureGroupAdjuster: ClosureGroupAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClosureGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the closure group steps in order and keeps a trace of each.
    final class ClosureGroupEngine {
        var steps: [any ClosureGroupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosureGroupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ClosureGroup) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [ClosureGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultClosureGroupEngine(_ flags: Kit.Flags.Registry) -> ClosureGroupEngine {
        return ClosureGroupEngine(
            steps: [
                ClosureGroupCostOffsetAdjuster(weight: 0.69),
                TieredClosureGroupAdjuster(bounds: [5107.0, 5818.0, 7475.0], rates: [0.82, 1.12, 1.06]),
                FacilityClosureGroupAdjuster(factors: ["east": 0.95, "online": 1.38]),
                FlaggedClosureGroupAdjuster(flags: flags, flag: "closure-group-weighted", percent: 3.6),
                RoundingClosureGroupAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 27111.7
        )
    }
}
