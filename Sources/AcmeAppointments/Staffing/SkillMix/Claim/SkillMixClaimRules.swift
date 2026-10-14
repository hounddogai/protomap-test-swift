import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a skill mix claim must pass. Check returns its problems, or none.
    protocol SkillMixClaimRule {
        func check(_ item: SkillMixClaim) -> [String]
    }

    final class SkillMixClaimRequiredOwnerIDRule: SkillMixClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixClaim) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixClaimRequiredCodeRule: SkillMixClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixClaimCodeLengthRule: SkillMixClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SkillMixClaimRequiredTitleRule: SkillMixClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SkillMixClaim) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SkillMixClaimOwnerIDLengthRule: SkillMixClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SkillMixClaim) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SkillMixClaimCodePrefixRule: SkillMixClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SkillMixClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a skill mix claim.
    final class SkillMixClaimValidator {
        var rules: [any SkillMixClaimRule]

        init(rules: [any SkillMixClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: SkillMixClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SkillMixClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SkillMixClaim]) -> [String: [String]] {
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

    static func defaultSkillMixClaimValidator() -> SkillMixClaimValidator {
        return SkillMixClaimValidator(
            rules: [
                SkillMixClaimRequiredOwnerIDRule(message: "skill mix claim needs a value"),
                SkillMixClaimRequiredCodeRule(message: "skill mix claim needs this field"),
                SkillMixClaimCodeLengthRule(maxLength: 80),
                SkillMixClaimRequiredTitleRule(message: "skill mix claim needs a value"),
                SkillMixClaimOwnerIDLengthRule(maxLength: 32),
                SkillMixClaimCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
