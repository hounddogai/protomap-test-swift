import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the scheduled follow up digest calculation.
    protocol ScheduledFollowUpDigestAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledFollowUpDigest, value: Double) -> Double
    }

    final class MinimumScheduledFollowUpDigestAdjuster: ScheduledFollowUpDigestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledFollowUpDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ScheduledFollowUpDigestExpiresAtOffsetAdjuster: ScheduledFollowUpDigestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: ScheduledFollowUpDigest, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class TieredScheduledFollowUpDigestAdjuster: ScheduledFollowUpDigestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledFollowUpDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the scheduled follow up digest steps in order and keeps a trace of each.
    final class ScheduledFollowUpDigestEngine {
        var steps: [any ScheduledFollowUpDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledFollowUpDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledFollowUpDigest) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledFollowUpDigestAdjuster = steps[index]
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

        func evaluateAll(_ items: [ScheduledFollowUpDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledFollowUpDigestEngine() -> ScheduledFollowUpDigestEngine {
        return ScheduledFollowUpDigestEngine(
            steps: [
                MinimumScheduledFollowUpDigestAdjuster(minimum: 5.9),
                ScheduledFollowUpDigestExpiresAtOffsetAdjuster(weight: 1.34),
                TieredScheduledFollowUpDigestAdjuster(bounds: [5224.0, 7110.0], rates: [0.9, 0.81]),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 64895.2
        )
    }
}
