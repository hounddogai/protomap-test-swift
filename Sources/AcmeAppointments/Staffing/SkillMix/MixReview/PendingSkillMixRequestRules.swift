import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a pending skill mix request must pass. Check returns its problems, or none.
    protocol PendingSkillMixRequestRule {
        func check(_ item: PendingSkillMixRequest) -> [String]
    }

    final class PendingSkillMixRequestCodePrefixRule: PendingSkillMixRequestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingSkillMixRequest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingSkillMixRequestRequiredCodeRule: PendingSkillMixRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingSkillMixRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingSkillMixRequestEndsAtRangeRule: PendingSkillMixRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingSkillMixRequest) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingSkillMixRequestRequiredChecksumRule: PendingSkillMixRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingSkillMixRequest) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingSkillMixRequestCodeLengthRule: PendingSkillMixRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingSkillMixRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingSkillMixRequestNameLengthRule: PendingSkillMixRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingSkillMixRequest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending skill mix request.
    final class PendingSkillMixRequestValidator {
        var rules: [any PendingSkillMixRequestRule]

        init(rules: [any PendingSkillMixRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingSkillMixRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingSkillMixRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingSkillMixRequest]) -> [String: [String]] {
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

    static func defaultPendingSkillMixRequestValidator() -> PendingSkillMixRequestValidator {
        return PendingSkillMixRequestValidator(
            rules: [
                PendingSkillMixRequestCodePrefixRule(prefix: "REF"),
                PendingSkillMixRequestRequiredCodeRule(message: "pending skill mix request needs a value"),
                PendingSkillMixRequestEndsAtRangeRule(min: 86400, max: 86400),
                PendingSkillMixRequestRequiredChecksumRule(message: "pending skill mix request needs a value"),
                PendingSkillMixRequestCodeLengthRule(maxLength: 86400),
                PendingSkillMixRequestNameLengthRule(maxLength: 32),
            ]
        )
    }
}
