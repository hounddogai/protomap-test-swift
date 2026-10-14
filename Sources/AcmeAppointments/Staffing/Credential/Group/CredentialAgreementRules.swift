import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential agreement must pass. Check returns its problems, or none.
    protocol CredentialAgreementRule {
        func check(_ item: CredentialAgreement) -> [String]
    }

    final class CredentialAgreementLimitRangeRule: CredentialAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialAgreement) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CredentialAgreementRequiredCategoryRule: CredentialAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialAgreement) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialAgreementVisitMinutesRangeRule: CredentialAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialAgreement) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CredentialAgreementRequiredSegmentRule: CredentialAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialAgreement) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialAgreementTitleLengthRule: CredentialAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialAgreement) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialAgreementCreatedAtRangeRule: CredentialAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialAgreement) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a credential agreement.
    final class CredentialAgreementValidator {
        var rules: [any CredentialAgreementRule]

        init(rules: [any CredentialAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialAgreement) -> [String] {
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

        func requireValid(_ item: CredentialAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialAgreement]) -> [String: [String]] {
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

    static func defaultCredentialAgreementValidator() -> CredentialAgreementValidator {
        return CredentialAgreementValidator(
            rules: [
                CredentialAgreementLimitRangeRule(min: 3600, max: 3600),
                CredentialAgreementRequiredCategoryRule(message: "credential agreement needs a value"),
                CredentialAgreementVisitMinutesRangeRule(min: 64, max: 3600),
                CredentialAgreementRequiredSegmentRule(message: "credential agreement needs a value"),
                CredentialAgreementTitleLengthRule(maxLength: 16),
                CredentialAgreementCreatedAtRangeRule(min: 16, max: 64),
            ]
        )
    }
}
