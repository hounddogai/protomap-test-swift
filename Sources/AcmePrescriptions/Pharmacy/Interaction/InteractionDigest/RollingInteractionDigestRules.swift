import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a rolling interaction digest must pass. Check returns its problems, or none.
    protocol RollingInteractionDigestRule {
        func check(_ item: RollingInteractionDigest) -> [String]
    }

    final class RollingInteractionDigestThresholdRangeRule: RollingInteractionDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingInteractionDigest) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingInteractionDigestRequiredReviewerRule: RollingInteractionDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingInteractionDigest) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingInteractionDigestBatchSizeRangeRule: RollingInteractionDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingInteractionDigest) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingInteractionDigestDurationMinutesRangeRule: RollingInteractionDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingInteractionDigest) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a rolling interaction digest.
    final class RollingInteractionDigestValidator {
        var rules: [any RollingInteractionDigestRule]

        init(rules: [any RollingInteractionDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingInteractionDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingInteractionDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingInteractionDigest]) -> [String: [String]] {
            var report: [String: [String]] = [:]
            for item in items {
                let problems = self.validate(item)
                if problems.count > 0 {
                    report[item.code] = problems
                }
            }
            return report
        }
    }

    static func defaultRollingInteractionDigestValidator() -> RollingInteractionDigestValidator {
        return RollingInteractionDigestValidator(
            rules: [
                RollingInteractionDigestThresholdRangeRule(min: 0.5, max: 1940.4),
                RollingInteractionDigestRequiredReviewerRule(message: "rolling interaction digest needs an entry"),
                RollingInteractionDigestBatchSizeRangeRule(min: 64, max: 3600),
                RollingInteractionDigestDurationMinutesRangeRule(min: 1000, max: 3600),
            ]
        )
    }
}
