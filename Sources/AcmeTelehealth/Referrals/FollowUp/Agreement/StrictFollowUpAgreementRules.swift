import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a strict follow up agreement must pass. Check returns its problems, or none.
    protocol StrictFollowUpAgreementRule {
        func check(_ item: StrictFollowUpAgreement) -> [String]
    }

    final class StrictFollowUpAgreementRequiredNameRule: StrictFollowUpAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictFollowUpAgreement) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictFollowUpAgreementNameLengthRule: StrictFollowUpAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictFollowUpAgreement) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictFollowUpAgreementCreatedAtRangeRule: StrictFollowUpAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictFollowUpAgreement) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict follow up agreement.
    final class StrictFollowUpAgreementValidator {
        var rules: [any StrictFollowUpAgreementRule]

        init(rules: [any StrictFollowUpAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictFollowUpAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictFollowUpAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictFollowUpAgreement]) -> [String: [String]] {
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

    static func defaultStrictFollowUpAgreementValidator() -> StrictFollowUpAgreementValidator {
        return StrictFollowUpAgreementValidator(
            rules: [
                StrictFollowUpAgreementRequiredNameRule(message: "strict follow up agreement needs this field"),
                StrictFollowUpAgreementNameLengthRule(maxLength: 16),
                StrictFollowUpAgreementCreatedAtRangeRule(min: 64, max: 255),
            ]
        )
    }
}
