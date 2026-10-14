import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a pending skill mix digest must pass. Check returns its problems, or none.
    protocol PendingSkillMixDigestRule {
        func check(_ item: PendingSkillMixDigest) -> [String]
    }

    final class PendingSkillMixDigestRequiredCodeRule: PendingSkillMixDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingSkillMixDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingSkillMixDigestRevisionRangeRule: PendingSkillMixDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingSkillMixDigest) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingSkillMixDigestNotesLengthRule: PendingSkillMixDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingSkillMixDigest) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending skill mix digest.
    final class PendingSkillMixDigestValidator {
        var rules: [any PendingSkillMixDigestRule]

        init(rules: [any PendingSkillMixDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingSkillMixDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingSkillMixDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingSkillMixDigest]) -> [String: [String]] {
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

    static func defaultPendingSkillMixDigestValidator() -> PendingSkillMixDigestValidator {
        return PendingSkillMixDigestValidator(
            rules: [
                PendingSkillMixDigestRequiredCodeRule(message: "pending skill mix digest needs an entry"),
                PendingSkillMixDigestRevisionRangeRule(min: 64, max: 80),
                PendingSkillMixDigestNotesLengthRule(maxLength: 1000),
            ]
        )
    }
}
