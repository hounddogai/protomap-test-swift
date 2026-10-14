import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a fallback care protocol threshold must pass. Check returns its problems, or none.
    protocol FallbackCareProtocolThresholdRule {
        func check(_ item: FallbackCareProtocolThreshold) -> [String]
    }

    final class FallbackCareProtocolThresholdBedLengthRule: FallbackCareProtocolThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCareProtocolThreshold) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCareProtocolThresholdSequenceRangeRule: FallbackCareProtocolThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackCareProtocolThreshold) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackCareProtocolThresholdRequiredReviewerRule: FallbackCareProtocolThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCareProtocolThreshold) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCareProtocolThresholdReviewerLengthRule: FallbackCareProtocolThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCareProtocolThreshold) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCareProtocolThresholdRequiredTitleRule: FallbackCareProtocolThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCareProtocolThreshold) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCareProtocolThresholdAllowedReviewerRule: FallbackCareProtocolThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackCareProtocolThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is stale"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback care protocol threshold.
    final class FallbackCareProtocolThresholdValidator {
        var rules: [any FallbackCareProtocolThresholdRule]

        init(rules: [any FallbackCareProtocolThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackCareProtocolThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackCareProtocolThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackCareProtocolThreshold]) -> [String: [String]] {
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

    static func defaultFallbackCareProtocolThresholdValidator() -> FallbackCareProtocolThresholdValidator {
        return FallbackCareProtocolThresholdValidator(
            rules: [
                FallbackCareProtocolThresholdBedLengthRule(maxLength: 64),
                FallbackCareProtocolThresholdSequenceRangeRule(min: 120, max: 255),
                FallbackCareProtocolThresholdRequiredReviewerRule(
                    message: "fallback care protocol threshold needs a value"
                ),
                FallbackCareProtocolThresholdReviewerLengthRule(maxLength: 64),
                FallbackCareProtocolThresholdRequiredTitleRule(
                    message: "fallback care protocol threshold needs this field"
                ),
                FallbackCareProtocolThresholdAllowedReviewerRule(allowed: []),
            ]
        )
    }
}
