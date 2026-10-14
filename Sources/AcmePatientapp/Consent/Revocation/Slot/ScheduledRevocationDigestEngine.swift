import AcmePlatform
import Foundation

extension Consent {
    /// One step of the scheduled revocation digest calculation.
    protocol ScheduledRevocationDigestFactor {
        func describe() -> String
        func adjust(_ item: ScheduledRevocationDigest, value: Double) -> Double
    }

    final class PercentScheduledRevocationDigestAdjuster: ScheduledRevocationDigestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledRevocationDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredScheduledRevocationDigestAdjuster: ScheduledRevocationDigestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledRevocationDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumScheduledRevocationDigestAdjuster: ScheduledRevocationDigestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledRevocationDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ScheduledRevocationDigestMinimumOffsetAdjuster: ScheduledRevocationDigestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: ScheduledRevocationDigest, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class CapScheduledRevocationDigestAdjuster: ScheduledRevocationDigestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledRevocationDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedScheduledRevocationDigestAdjuster: ScheduledRevocationDigestFactor {
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

        func adjust(_ item: ScheduledRevocationDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled revocation digest steps in order and keeps a trace of each.
    final class ScheduledRevocationDigestEngine {
        var steps: [any ScheduledRevocationDigestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledRevocationDigestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ScheduledRevocationDigest) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledRevocationDigestFactor = steps[index]
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

        func evaluateAll(_ items: [ScheduledRevocationDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultScheduledRevocationDigestEngine(_ flags: Kit.Flags.Registry) -> ScheduledRevocationDigestEngine {
        return ScheduledRevocationDigestEngine(
            steps: [
                PercentScheduledRevocationDigestAdjuster(percent: 0.2),
                TieredScheduledRevocationDigestAdjuster(bounds: [4323.0, 5926.0, 6243.0], rates: [1.11, 1.17, 0.81]),
                MinimumScheduledRevocationDigestAdjuster(minimum: 38.9),
                ScheduledRevocationDigestMinimumOffsetAdjuster(weight: 0.47),
                CapScheduledRevocationDigestAdjuster(cap: 28042.0),
                FlaggedScheduledRevocationDigestAdjuster(
                    flags: flags,
                    flag: "scheduled-revocation-digest-rolling",
                    percent: 3.2
                ),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 81179.6
        )
    }
}
