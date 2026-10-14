import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a default risk score threshold must pass. Check returns its problems, or none.
    protocol DefaultRiskScoreThresholdRule {
        func check(_ item: DefaultRiskScoreThreshold) -> [String]
    }

    final class DefaultRiskScoreThresholdCodeLengthRule: DefaultRiskScoreThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRiskScoreThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultRiskScoreThresholdAllowedTitleRule: DefaultRiskScoreThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultRiskScoreThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is inconsistent"]
            }
            return []
        }
    }

    final class DefaultRiskScoreThresholdTitleLengthRule: DefaultRiskScoreThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRiskScoreThreshold) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultRiskScoreThresholdRequiredCodeRule: DefaultRiskScoreThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultRiskScoreThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default risk score threshold.
    final class DefaultRiskScoreThresholdValidator {
        var rules: [any DefaultRiskScoreThresholdRule]

        init(rules: [any DefaultRiskScoreThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultRiskScoreThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultRiskScoreThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultRiskScoreThreshold]) -> [String: [String]] {
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

    static func defaultDefaultRiskScoreThresholdValidator() -> DefaultRiskScoreThresholdValidator {
        return DefaultRiskScoreThresholdValidator(
            rules: [
                DefaultRiskScoreThresholdCodeLengthRule(maxLength: 80),
                DefaultRiskScoreThresholdAllowedTitleRule(allowed: ["primary", "adaptive"]),
                DefaultRiskScoreThresholdTitleLengthRule(maxLength: 1000),
                DefaultRiskScoreThresholdRequiredCodeRule(message: "default risk score threshold needs an entry"),
            ]
        )
    }
}
