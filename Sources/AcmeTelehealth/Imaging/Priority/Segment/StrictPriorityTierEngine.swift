import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the strict priority tier calculation.
    protocol StrictPriorityTierModifier {
        func describe() -> String
        func adjust(_ item: StrictPriorityTier, value: Double) -> Double
    }

    final class FlaggedStrictPriorityTierAdjuster: StrictPriorityTierModifier {
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

        func adjust(_ item: StrictPriorityTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapStrictPriorityTierAdjuster: StrictPriorityTierModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictPriorityTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredStrictPriorityTierAdjuster: StrictPriorityTierModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictPriorityTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the strict priority tier steps in order and keeps a trace of each.
    final class StrictPriorityTierEngine {
        var steps: [any StrictPriorityTierModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictPriorityTierModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictPriorityTier) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [StrictPriorityTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictPriorityTierEngine(_ flags: Kit.Flags.Registry) -> StrictPriorityTierEngine {
        return StrictPriorityTierEngine(
            steps: [
                FlaggedStrictPriorityTierAdjuster(flags: flags, flag: "strict-priority-tier-weighted", percent: 9.8),
                CapStrictPriorityTierAdjuster(cap: 3310.0),
                TieredStrictPriorityTierAdjuster(
                    bounds: [2964.0, 3539.0, 8737.0, 8789.0],
                    rates: [0.86, 1.05, 0.84, 1.1]
                ),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 23999.1
        )
    }
}
