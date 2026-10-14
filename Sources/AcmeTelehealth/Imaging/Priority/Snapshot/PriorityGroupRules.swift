import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority group must pass. Check returns its problems, or none.
    protocol PriorityGroupRule {
        func check(_ item: PriorityGroup) -> [String]
    }

    final class PriorityGroupLabelLengthRule: PriorityGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityGroup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityGroupCodeLengthRule: PriorityGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityGroupRequiredCodeRule: PriorityGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a priority group.
    final class PriorityGroupValidator {
        var rules: [any PriorityGroupRule]

        init(rules: [any PriorityGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityGroup) -> [String] {
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

        func requireValid(_ item: PriorityGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityGroup]) -> [String: [String]] {
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

    static func defaultPriorityGroupValidator() -> PriorityGroupValidator {
        return PriorityGroupValidator(
            rules: [
                PriorityGroupLabelLengthRule(maxLength: 3600),
                PriorityGroupCodeLengthRule(maxLength: 1000),
                PriorityGroupRequiredCodeRule(message: "priority group needs this field"),
            ]
        )
    }
}
