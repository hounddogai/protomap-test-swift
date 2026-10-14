import AcmePlatform
import Foundation

extension Labs {
    /// One step of the adaptive courier milestone calculation.
    protocol AdaptiveCourierMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveCourierMilestone, value: Double) -> Double
    }

    final class AdaptiveCourierMilestoneBudgetOffsetAdjuster: AdaptiveCourierMilestoneAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: AdaptiveCourierMilestone, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class TieredAdaptiveCourierMilestoneAdjuster: AdaptiveCourierMilestoneAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveCourierMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedAdaptiveCourierMilestoneAdjuster: AdaptiveCourierMilestoneAdjuster {
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

        func adjust(_ item: AdaptiveCourierMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAdaptiveCourierMilestoneAdjuster: AdaptiveCourierMilestoneAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveCourierMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingAdaptiveCourierMilestoneAdjuster: AdaptiveCourierMilestoneAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveCourierMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the adaptive courier milestone steps in order and keeps a trace of each.
    final class AdaptiveCourierMilestoneEngine {
        var steps: [any AdaptiveCourierMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveCourierMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveCourierMilestone) -> Double {
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

        func evaluateAll(_ items: [AdaptiveCourierMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveCourierMilestoneEngine(_ flags: Kit.Flags.Registry) -> AdaptiveCourierMilestoneEngine {
        return AdaptiveCourierMilestoneEngine(
            steps: [
                AdaptiveCourierMilestoneBudgetOffsetAdjuster(weight: 0.55),
                TieredAdaptiveCourierMilestoneAdjuster(bounds: [211.0, 1820.0, 4417.0], rates: [1.04, 0.9, 0.83]),
                FlaggedAdaptiveCourierMilestoneAdjuster(
                    flags: flags,
                    flag: "adaptive-courier-milestone-fallback",
                    percent: -2.4
                ),
                CapAdaptiveCourierMilestoneAdjuster(cap: 37496.0),
                RoundingAdaptiveCourierMilestoneAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 20154.5
        )
    }
}
