import AcmePlatform
import Foundation

extension Consent {
    /// A rule a rolling disclosure agreement must pass. Check returns its problems, or none.
    protocol RollingDisclosureAgreementRule {
        func check(_ item: RollingDisclosureAgreement) -> [String]
    }

    final class RollingDisclosureAgreementRequiredCodeRule: RollingDisclosureAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingDisclosureAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingDisclosureAgreementCreatedAtRangeRule: RollingDisclosureAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingDisclosureAgreement) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingDisclosureAgreementApprovedGuardRule: RollingDisclosureAgreementRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RollingDisclosureAgreement) -> [String] {
            if item.approved && (item.createdAt > limit) {
                return ["created at \(item.createdAt) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class RollingDisclosureAgreementRequiredTitleRule: RollingDisclosureAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingDisclosureAgreement) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling disclosure agreement.
    final class RollingDisclosureAgreementValidator {
        var rules: [any RollingDisclosureAgreementRule]

        init(rules: [any RollingDisclosureAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingDisclosureAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingDisclosureAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingDisclosureAgreement]) -> [String: [String]] {
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

    static func defaultRollingDisclosureAgreementValidator() -> RollingDisclosureAgreementValidator {
        return RollingDisclosureAgreementValidator(
            rules: [
                RollingDisclosureAgreementRequiredCodeRule(message: "rolling disclosure agreement needs an entry"),
                RollingDisclosureAgreementCreatedAtRangeRule(min: 16, max: 64),
                RollingDisclosureAgreementApprovedGuardRule(limit: 86400),
                RollingDisclosureAgreementRequiredTitleRule(message: "rolling disclosure agreement needs an entry"),
            ]
        )
    }
}
