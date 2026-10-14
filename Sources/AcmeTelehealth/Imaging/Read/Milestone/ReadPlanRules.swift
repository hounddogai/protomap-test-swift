import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read plan must pass. Check returns its problems, or none.
    protocol ReadPlanRule {
        func check(_ item: ReadPlan) -> [String]
    }

    final class ReadPlanCodePrefixRule: ReadPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReadPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ReadPlanCodeLengthRule: ReadPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadPlanRequiredProcedureCodeRule: ReadPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadPlan) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a read plan.
    final class ReadPlanValidator {
        var rules: [any ReadPlanRule]

        init(rules: [any ReadPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReadPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadPlan]) -> [String: [String]] {
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

    static func defaultReadPlanValidator() -> ReadPlanValidator {
        return ReadPlanValidator(
            rules: [
                ReadPlanCodePrefixRule(prefix: "X"),
                ReadPlanCodeLengthRule(maxLength: 120),
                ReadPlanRequiredProcedureCodeRule(message: "read plan needs this field"),
            ]
        )
    }
}
