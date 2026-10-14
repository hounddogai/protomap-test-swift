import AcmePlatform
import Foundation

extension Labs {
    /// One step of the default courier claim calculation.
    protocol DefaultCourierClaimAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultCourierClaim, value: Double) -> Double
    }

    final class TieredDefaultCourierClaimAdjuster: DefaultCourierClaimAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultCourierClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class DefaultCourierClaimStartsAtOffsetAdjuster: DefaultCourierClaimAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: DefaultCourierClaim, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class PercentDefaultCourierClaimAdjuster: DefaultCourierClaimAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultCourierClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedDefaultCourierClaimAdjuster: DefaultCourierClaimAdjuster {
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

        func adjust(_ item: DefaultCourierClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default courier claim steps in order and keeps a trace of each.
    final class DefaultCourierClaimEngine {
        var steps: [any DefaultCourierClaimAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultCourierClaimAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultCourierClaim) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultCourierClaimAdjuster = steps[index]
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

        func evaluateAll(_ items: [DefaultCourierClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultCourierClaimEngine(_ flags: Kit.Flags.Registry) -> DefaultCourierClaimEngine {
        return DefaultCourierClaimEngine(
            steps: [
                TieredDefaultCourierClaimAdjuster(
                    bounds: [2661.0, 3593.0, 5420.0, 6844.0],
                    rates: [1.15, 0.95, 0.91, 1.18]
                ),
                DefaultCourierClaimStartsAtOffsetAdjuster(weight: 1.19),
                PercentDefaultCourierClaimAdjuster(percent: 14.3),
                FlaggedDefaultCourierClaimAdjuster(flags: flags, flag: "default-courier-claim-rolling", percent: -2.9),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 4917.2
        )
    }
}
