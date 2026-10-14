import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert digest must pass. Check returns its problems, or none.
    protocol AlertDigestRule {
        func check(_ item: AlertDigest) -> [String]
    }

    final class AlertDigestRequiredLabelRule: AlertDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertDigest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertDigestLabelLengthRule: AlertDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertDigest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertDigestTagsLimitRule: AlertDigestRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: AlertDigest) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class AlertDigestAllergyLengthRule: AlertDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertDigest) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertDigestRequiredCodeRule: AlertDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a alert digest.
    final class AlertDigestValidator {
        var rules: [any AlertDigestRule]

        init(rules: [any AlertDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: AlertDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertDigest]) -> [String: [String]] {
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

    static func defaultAlertDigestValidator() -> AlertDigestValidator {
        return AlertDigestValidator(
            rules: [
                AlertDigestRequiredLabelRule(message: "alert digest needs a value"),
                AlertDigestLabelLengthRule(maxLength: 32),
                AlertDigestTagsLimitRule(maxCount: 120, banned: ["legacy", "weighted"]),
                AlertDigestAllergyLengthRule(maxLength: 80),
                AlertDigestRequiredCodeRule(message: "alert digest needs a value"),
            ]
        )
    }
}
