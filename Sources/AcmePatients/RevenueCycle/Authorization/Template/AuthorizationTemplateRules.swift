import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization template must pass. Check returns its problems, or none.
    protocol AuthorizationTemplateRule {
        func check(_ item: AuthorizationTemplate) -> [String]
    }

    final class AuthorizationTemplateGraceDaysRangeRule: AuthorizationTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationTemplate) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AuthorizationTemplateRequiredPatientRefRule: AuthorizationTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationTemplate) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationTemplateChecksumLengthRule: AuthorizationTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationTemplate) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationTemplateNameLengthRule: AuthorizationTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationTemplate) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationTemplateCodeLengthRule: AuthorizationTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AuthorizationTemplateRefillsRangeRule: AuthorizationTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AuthorizationTemplate) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization template.
    final class AuthorizationTemplateValidator {
        var rules: [any AuthorizationTemplateRule]

        init(rules: [any AuthorizationTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationTemplate) -> [String] {
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

        func requireValid(_ item: AuthorizationTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationTemplate]) -> [String: [String]] {
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

    static func defaultAuthorizationTemplateValidator() -> AuthorizationTemplateValidator {
        return AuthorizationTemplateValidator(
            rules: [
                AuthorizationTemplateGraceDaysRangeRule(min: 255, max: 255),
                AuthorizationTemplateRequiredPatientRefRule(message: "authorization template needs this field"),
                AuthorizationTemplateChecksumLengthRule(maxLength: 255),
                AuthorizationTemplateNameLengthRule(maxLength: 16),
                AuthorizationTemplateCodeLengthRule(maxLength: 80),
                AuthorizationTemplateRefillsRangeRule(min: 64, max: 1000),
            ]
        )
    }
}
