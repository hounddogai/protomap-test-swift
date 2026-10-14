import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up record calculation.
    protocol FollowUpRecordAdjuster {
        func describe() -> String
        func adjust(_ item: FollowUpRecord, value: Double) -> Double
    }

    final class FlaggedFollowUpRecordAdjuster: FollowUpRecordAdjuster {
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

        func adjust(_ item: FollowUpRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumFollowUpRecordAdjuster: FollowUpRecordAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FollowUpRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FollowUpRecordWeightOffsetAdjuster: FollowUpRecordAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: FollowUpRecord, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class PercentFollowUpRecordAdjuster: FollowUpRecordAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FollowUpRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredFollowUpRecordAdjuster: FollowUpRecordAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FollowUpRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the follow up record steps in order and keeps a trace of each.
    final class FollowUpRecordEngine {
        var steps: [any FollowUpRecordAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpRecordAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FollowUpRecord) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any FollowUpRecordAdjuster = steps[index]
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

        func evaluateAll(_ items: [FollowUpRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFollowUpRecordEngine(_ flags: Kit.Flags.Registry) -> FollowUpRecordEngine {
        return FollowUpRecordEngine(
            steps: [
                FlaggedFollowUpRecordAdjuster(flags: flags, flag: "follow-up-record-tiered", percent: -9.2),
                MinimumFollowUpRecordAdjuster(minimum: 26.4),
                FollowUpRecordWeightOffsetAdjuster(weight: 0.69),
                PercentFollowUpRecordAdjuster(percent: -6.0),
                TieredFollowUpRecordAdjuster(
                    bounds: [3123.0, 4275.0, 5207.0, 6909.0],
                    rates: [0.84, 1.15, 1.01, 0.97]
                ),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 13839.8
        )
    }
}
