import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the primary priority profile calculation.
    protocol PrimaryPriorityProfileAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryPriorityProfile, value: Double) -> Double
    }

    final class FlaggedPrimaryPriorityProfileAdjuster: PrimaryPriorityProfileAdjuster {
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

        func adjust(_ item: PrimaryPriorityProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NamePrimaryPriorityProfileAdjuster: PrimaryPriorityProfileAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: PrimaryPriorityProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapPrimaryPriorityProfileAdjuster: PrimaryPriorityProfileAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryPriorityProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentPrimaryPriorityProfileAdjuster: PrimaryPriorityProfileAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryPriorityProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPrimaryPriorityProfileAdjuster: PrimaryPriorityProfileAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryPriorityProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredPrimaryPriorityProfileAdjuster: PrimaryPriorityProfileAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryPriorityProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the primary priority profile steps in order and keeps a trace of each.
    final class PrimaryPriorityProfileEngine {
        var steps: [any PrimaryPriorityProfileAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryPriorityProfileAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryPriorityProfile) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryPriorityProfileAdjuster = steps[index]
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

        func evaluateAll(_ items: [PrimaryPriorityProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryPriorityProfileEngine(_ flags: Kit.Flags.Registry) -> PrimaryPriorityProfileEngine {
        return PrimaryPriorityProfileEngine(
            steps: [
                FlaggedPrimaryPriorityProfileAdjuster(
                    flags: flags,
                    flag: "primary-priority-profile-global",
                    percent: -7.3
                ),
                NamePrimaryPriorityProfileAdjuster(factors: ["north": 1.16, "retail": 1.26, "west": 1.29]),
                CapPrimaryPriorityProfileAdjuster(cap: 41992.0),
                PercentPrimaryPriorityProfileAdjuster(percent: 23.4),
                MinimumPrimaryPriorityProfileAdjuster(minimum: 24.2),
                TieredPrimaryPriorityProfileAdjuster(
                    bounds: [3301.0, 7195.0, 8925.0, 9871.0],
                    rates: [1.13, 0.82, 1.19, 0.87]
                ),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 68506.2
        )
    }
}
