import AcmePlatform
import Foundation

extension Consent {
    /// One step of the weighted proxy summary calculation.
    protocol WeightedProxySummaryStep {
        func describe() -> String
        func adjust(_ item: WeightedProxySummary, value: Double) -> Double
    }

    final class PercentWeightedProxySummaryAdjuster: WeightedProxySummaryStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedProxySummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedWeightedProxySummaryAdjuster: WeightedProxySummaryStep {
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

        func adjust(_ item: WeightedProxySummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilityWeightedProxySummaryAdjuster: WeightedProxySummaryStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: WeightedProxySummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapWeightedProxySummaryAdjuster: WeightedProxySummaryStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedProxySummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the weighted proxy summary steps in order and keeps a trace of each.
    final class WeightedProxySummaryEngine {
        var steps: [any WeightedProxySummaryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedProxySummaryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WeightedProxySummary) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedProxySummaryStep = steps[index]
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

        func evaluateAll(_ items: [WeightedProxySummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWeightedProxySummaryEngine(_ flags: Kit.Flags.Registry) -> WeightedProxySummaryEngine {
        return WeightedProxySummaryEngine(
            steps: [
                PercentWeightedProxySummaryAdjuster(percent: -9.3),
                FlaggedWeightedProxySummaryAdjuster(
                    flags: flags,
                    flag: "weighted-proxy-summary-lenient",
                    percent: 2.5
                ),
                FacilityWeightedProxySummaryAdjuster(factors: ["east": 1.3]),
                CapWeightedProxySummaryAdjuster(cap: 4449.0),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 42661.5
        )
    }
}
