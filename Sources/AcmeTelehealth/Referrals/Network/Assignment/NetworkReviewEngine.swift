import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network review calculation.
    protocol NetworkReviewFactor {
        func describe() -> String
        func adjust(_ item: NetworkReview, value: Double) -> Double
    }

    final class FlaggedNetworkReviewAdjuster: NetworkReviewFactor {
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

        func adjust(_ item: NetworkReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentNetworkReviewAdjuster: NetworkReviewFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: NetworkReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NetworkReviewDurationMinutesOffsetAdjuster: NetworkReviewFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: NetworkReview, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class MinimumNetworkReviewAdjuster: NetworkReviewFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: NetworkReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the network review steps in order and keeps a trace of each.
    final class NetworkReviewEngine {
        var steps: [any NetworkReviewFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkReviewFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: NetworkReview) -> Double {
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

        func evaluateAll(_ items: [NetworkReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultNetworkReviewEngine(_ flags: Kit.Flags.Registry) -> NetworkReviewEngine {
        return NetworkReviewEngine(
            steps: [
                FlaggedNetworkReviewAdjuster(flags: flags, flag: "network-review-primary", percent: 6.0),
                PercentNetworkReviewAdjuster(percent: 12.1),
                NetworkReviewDurationMinutesOffsetAdjuster(weight: 0.41),
                MinimumNetworkReviewAdjuster(minimum: 12.6),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 64024.6
        )
    }
}
