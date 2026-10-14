import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a rolling priority group must pass. Check returns its problems, or none.
    protocol RollingPriorityGroupRule {
        func check(_ item: RollingPriorityGroup) -> [String]
    }

    final class RollingPriorityGroupCodeLengthRule: RollingPriorityGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingPriorityGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingPriorityGroupTitleLengthRule: RollingPriorityGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingPriorityGroup) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingPriorityGroupRequiredChecksumRule: RollingPriorityGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingPriorityGroup) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling priority group.
    final class RollingPriorityGroupValidator {
        var rules: [any RollingPriorityGroupRule]

        init(rules: [any RollingPriorityGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingPriorityGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingPriorityGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingPriorityGroup]) -> [String: [String]] {
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

    static func defaultRollingPriorityGroupValidator() -> RollingPriorityGroupValidator {
        return RollingPriorityGroupValidator(
            rules: [
                RollingPriorityGroupCodeLengthRule(maxLength: 64),
                RollingPriorityGroupTitleLengthRule(maxLength: 120),
                RollingPriorityGroupRequiredChecksumRule(message: "rolling priority group needs this field"),
            ]
        )
    }
}
