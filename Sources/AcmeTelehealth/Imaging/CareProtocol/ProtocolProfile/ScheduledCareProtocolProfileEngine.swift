import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the scheduled care protocol profile calculation.
    protocol ScheduledCareProtocolProfileStep {
        func describe() -> String
        func adjust(_ item: ScheduledCareProtocolProfile, value: Double) -> Double
    }

    final class TieredScheduledCareProtocolProfileAdjuster: ScheduledCareProtocolProfileStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledCareProtocolProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ScheduledCareProtocolProfileVisitMinutesOffsetAdjuster: ScheduledCareProtocolProfileStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: ScheduledCareProtocolProfile, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class RoundingScheduledCareProtocolProfileAdjuster: ScheduledCareProtocolProfileStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledCareProtocolProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedScheduledCareProtocolProfileAdjuster: ScheduledCareProtocolProfileStep {
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

        func adjust(_ item: ScheduledCareProtocolProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CountryScheduledCareProtocolProfileAdjuster: ScheduledCareProtocolProfileStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: ScheduledCareProtocolProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the scheduled care protocol profile steps in order and keeps a trace of each.
    final class ScheduledCareProtocolProfileEngine {
        var steps: [any ScheduledCareProtocolProfileStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledCareProtocolProfileStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledCareProtocolProfile) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledCareProtocolProfileStep = steps[index]
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

        func evaluateAll(_ items: [ScheduledCareProtocolProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledCareProtocolProfileEngine(_ flags: Kit.Flags.Registry) -> ScheduledCareProtocolProfileEngine {
        return ScheduledCareProtocolProfileEngine(
            steps: [
                TieredScheduledCareProtocolProfileAdjuster(
                    bounds: [1068.0, 4057.0, 5288.0, 8052.0],
                    rates: [0.96, 1.03, 0.99, 1.03]
                ),
                ScheduledCareProtocolProfileVisitMinutesOffsetAdjuster(weight: 1.8),
                RoundingScheduledCareProtocolProfileAdjuster(step: 1.0),
                FlaggedScheduledCareProtocolProfileAdjuster(
                    flags: flags,
                    flag: "scheduled-care-protocol-profile-primary",
                    percent: -4.2
                ),
                CountryScheduledCareProtocolProfileAdjuster(factors: ["online": 0.74, "central": 1.09]),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 43136.7
        )
    }
}
