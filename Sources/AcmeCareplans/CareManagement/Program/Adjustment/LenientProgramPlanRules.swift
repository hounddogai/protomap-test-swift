import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a lenient program plan must pass. Check returns its problems, or none.
    protocol LenientProgramPlanRule {
        func check(_ item: LenientProgramPlan) -> [String]
    }

    final class LenientProgramPlanRequiredNameRule: LenientProgramPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientProgramPlan) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientProgramPlanCodeLengthRule: LenientProgramPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientProgramPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientProgramPlanCodePrefixRule: LenientProgramPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientProgramPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient program plan.
    final class LenientProgramPlanValidator {
        var rules: [any LenientProgramPlanRule]

        init(rules: [any LenientProgramPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientProgramPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientProgramPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientProgramPlan]) -> [String: [String]] {
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

    static func defaultLenientProgramPlanValidator() -> LenientProgramPlanValidator {
        return LenientProgramPlanValidator(
            rules: [
                LenientProgramPlanRequiredNameRule(message: "lenient program plan needs this field"),
                LenientProgramPlanCodeLengthRule(maxLength: 120),
                LenientProgramPlanCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
