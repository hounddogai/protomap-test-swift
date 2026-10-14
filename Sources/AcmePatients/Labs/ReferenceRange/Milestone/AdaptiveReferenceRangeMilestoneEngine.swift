import AcmePlatform
import Foundation

extension Labs {
    /// One step of the adaptive reference range milestone calculation.
    protocol AdaptiveReferenceRangeMilestoneStep {
        func describe() -> String
        func adjust(_ item: AdaptiveReferenceRangeMilestone, value: Double) -> Double
    }

    final class CapAdaptiveReferenceRangeMilestoneAdjuster: AdaptiveReferenceRangeMilestoneStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveReferenceRangeMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedAdaptiveReferenceRangeMilestoneAdjuster: AdaptiveReferenceRangeMilestoneStep {
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

        func adjust(_ item: AdaptiveReferenceRangeMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAdaptiveReferenceRangeMilestoneAdjuster: AdaptiveReferenceRangeMilestoneStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveReferenceRangeMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingAdaptiveReferenceRangeMilestoneAdjuster: AdaptiveReferenceRangeMilestoneStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveReferenceRangeMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentAdaptiveReferenceRangeMilestoneAdjuster: AdaptiveReferenceRangeMilestoneStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveReferenceRangeMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AdaptiveReferenceRangeMilestoneVersionOffsetAdjuster: AdaptiveReferenceRangeMilestoneStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: AdaptiveReferenceRangeMilestone, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    /// Runs the adaptive reference range milestone steps in order and keeps a trace of each.
    final class AdaptiveReferenceRangeMilestoneEngine {
        var steps: [any AdaptiveReferenceRangeMilestoneStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveReferenceRangeMilestoneStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveReferenceRangeMilestone) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveReferenceRangeMilestoneStep = steps[index]
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

        func evaluateAll(_ items: [AdaptiveReferenceRangeMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveReferenceRangeMilestoneEngine(_ flags: Kit.Flags.Registry) -> AdaptiveReferenceRangeMilestoneEngine {
        return AdaptiveReferenceRangeMilestoneEngine(
            steps: [
                CapAdaptiveReferenceRangeMilestoneAdjuster(cap: 2973.0),
                FlaggedAdaptiveReferenceRangeMilestoneAdjuster(
                    flags: flags,
                    flag: "adaptive-reference-range-milestone-strict",
                    percent: 9.9
                ),
                TieredAdaptiveReferenceRangeMilestoneAdjuster(
                    bounds: [3607.0, 3667.0, 6932.0, 7245.0],
                    rates: [1.08, 1.1, 1.17, 0.81]
                ),
                RoundingAdaptiveReferenceRangeMilestoneAdjuster(step: 0.05),
                PercentAdaptiveReferenceRangeMilestoneAdjuster(percent: -0.6),
                AdaptiveReferenceRangeMilestoneVersionOffsetAdjuster(weight: 0.43),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 10148.7
        )
    }
}
