import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment digest must pass. Check returns its problems, or none.
    protocol AssessmentDigestRule {
        func check(_ item: AssessmentDigest) -> [String]
    }

    final class AssessmentDigestRetriesRangeRule: AssessmentDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentDigest) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AssessmentDigestAllowedSourceRule: AssessmentDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AssessmentDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.source)) {
                return ["source \(item.source) is below minimum"]
            }
            return []
        }
    }

    final class AssessmentDigestRequiredSourceRule: AssessmentDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentDigest) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentDigestRequiredLabelRule: AssessmentDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentDigest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentDigestCodePrefixRule: AssessmentDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AssessmentDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a assessment digest.
    final class AssessmentDigestValidator {
        var rules: [any AssessmentDigestRule]

        init(rules: [any AssessmentDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AssessmentDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentDigest]) -> [String: [String]] {
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

    static func defaultAssessmentDigestValidator() -> AssessmentDigestValidator {
        return AssessmentDigestValidator(
            rules: [
                AssessmentDigestRetriesRangeRule(min: 32, max: 86400),
                AssessmentDigestAllowedSourceRule(allowed: ["fallback", "fallback"]),
                AssessmentDigestRequiredSourceRule(message: "assessment digest needs an entry"),
                AssessmentDigestRequiredLabelRule(message: "assessment digest needs an entry"),
                AssessmentDigestCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
