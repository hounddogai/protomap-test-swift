import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up agreement must pass. Check returns its problems, or none.
    protocol FollowUpAgreementRule {
        func check(_ item: FollowUpAgreement) -> [String]
    }

    final class FollowUpAgreementScoreRangeRule: FollowUpAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpAgreement) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FollowUpAgreementRefillsRangeRule: FollowUpAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpAgreement) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FollowUpAgreementUnitLengthRule: FollowUpAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpAgreement) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpAgreementNameLengthRule: FollowUpAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpAgreement) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpAgreementRevisionRangeRule: FollowUpAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpAgreement) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FollowUpAgreementCodePrefixRule: FollowUpAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FollowUpAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a follow up agreement.
    final class FollowUpAgreementValidator {
        var rules: [any FollowUpAgreementRule]

        init(rules: [any FollowUpAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FollowUpAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpAgreement]) -> [String: [String]] {
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

    static func defaultFollowUpAgreementValidator() -> FollowUpAgreementValidator {
        return FollowUpAgreementValidator(
            rules: [
                FollowUpAgreementScoreRangeRule(min: 3.3, max: 2514.4),
                FollowUpAgreementRefillsRangeRule(min: 32, max: 1000),
                FollowUpAgreementUnitLengthRule(maxLength: 1000),
                FollowUpAgreementNameLengthRule(maxLength: 32),
                FollowUpAgreementRevisionRangeRule(min: 120, max: 86400),
                FollowUpAgreementCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
