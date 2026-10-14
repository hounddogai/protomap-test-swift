import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the credential review calculation.
    protocol CredentialReviewFactor {
        func describe() -> String
        func adjust(_ item: CredentialReview, value: Double) -> Double
    }

    final class FlaggedCredentialReviewAdjuster: CredentialReviewFactor {
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

        func adjust(_ item: CredentialReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCredentialReviewAdjuster: CredentialReviewFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CredentialReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapCredentialReviewAdjuster: CredentialReviewFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CredentialReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RegionCredentialReviewAdjuster: CredentialReviewFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: CredentialReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the credential review steps in order and keeps a trace of each.
    final class CredentialReviewEngine {
        var steps: [any CredentialReviewFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CredentialReviewFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CredentialReview) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [CredentialReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCredentialReviewEngine(_ flags: Kit.Flags.Registry) -> CredentialReviewEngine {
        return CredentialReviewEngine(
            steps: [
                FlaggedCredentialReviewAdjuster(flags: flags, flag: "credential-review-batched", percent: 2.1),
                MinimumCredentialReviewAdjuster(minimum: 47.4),
                CapCredentialReviewAdjuster(cap: 4233.0),
                RegionCredentialReviewAdjuster(factors: ["east": 1.06, "central": 0.94, "online": 1.19]),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 41093.3
        )
    }
}
