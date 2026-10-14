import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the default charge request calculation.
    protocol DefaultChargeRequestStep {
        func describe() -> String
        func adjust(_ item: DefaultChargeRequest, value: Double) -> Double
    }

    final class PercentDefaultChargeRequestAdjuster: DefaultChargeRequestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultChargeRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DefaultChargeRequestCeilingOffsetAdjuster: DefaultChargeRequestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: DefaultChargeRequest, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class MinimumDefaultChargeRequestAdjuster: DefaultChargeRequestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultChargeRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredDefaultChargeRequestAdjuster: DefaultChargeRequestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultChargeRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedDefaultChargeRequestAdjuster: DefaultChargeRequestStep {
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

        func adjust(_ item: DefaultChargeRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default charge request steps in order and keeps a trace of each.
    final class DefaultChargeRequestEngine {
        var steps: [any DefaultChargeRequestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultChargeRequestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultChargeRequest) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultChargeRequestStep = steps[index]
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

        func evaluateAll(_ items: [DefaultChargeRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultChargeRequestEngine(_ flags: Kit.Flags.Registry) -> DefaultChargeRequestEngine {
        return DefaultChargeRequestEngine(
            steps: [
                PercentDefaultChargeRequestAdjuster(percent: -24.4),
                DefaultChargeRequestCeilingOffsetAdjuster(weight: 0.22),
                MinimumDefaultChargeRequestAdjuster(minimum: 42.5),
                TieredDefaultChargeRequestAdjuster(bounds: [5630.0, 6916.0, 8316.0], rates: [1.04, 1.13, 1.06]),
                FlaggedDefaultChargeRequestAdjuster(
                    flags: flags,
                    flag: "default-charge-request-tiered",
                    percent: -2.7
                ),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 68976.0
        )
    }
}
