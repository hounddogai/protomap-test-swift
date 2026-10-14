import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment profile must pass. Check returns its problems, or none.
    protocol AssessmentProfileRule {
        func check(_ item: AssessmentProfile) -> [String]
    }

    final class AssessmentProfileRequiredChannelRule: AssessmentProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AssessmentProfile) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AssessmentProfileCodePrefixRule: AssessmentProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AssessmentProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AssessmentProfileAllowedNameRule: AssessmentProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AssessmentProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is inconsistent"]
            }
            return []
        }
    }

    final class AssessmentProfileProcedureCodeLengthRule: AssessmentProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentProfile) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentProfileVisibleGuardRule: AssessmentProfileRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: AssessmentProfile) -> [String] {
            if item.visible && (item.createdAt > limit) {
                return ["created at \(item.createdAt) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class AssessmentProfileNameLengthRule: AssessmentProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentProfile) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a assessment profile.
    final class AssessmentProfileValidator {
        var rules: [any AssessmentProfileRule]

        init(rules: [any AssessmentProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentProfile) -> [String] {
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

        func requireValid(_ item: AssessmentProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentProfile]) -> [String: [String]] {
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

    static func defaultAssessmentProfileValidator() -> AssessmentProfileValidator {
        return AssessmentProfileValidator(
            rules: [
                AssessmentProfileRequiredChannelRule(message: "assessment profile needs this field"),
                AssessmentProfileCodePrefixRule(prefix: "X"),
                AssessmentProfileAllowedNameRule(allowed: []),
                AssessmentProfileProcedureCodeLengthRule(maxLength: 3600),
                AssessmentProfileVisibleGuardRule(limit: 255),
                AssessmentProfileNameLengthRule(maxLength: 255),
            ]
        )
    }
}
