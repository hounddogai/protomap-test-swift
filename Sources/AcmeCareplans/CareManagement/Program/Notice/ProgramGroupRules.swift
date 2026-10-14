import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program group must pass. Check returns its problems, or none.
    protocol ProgramGroupRule {
        func check(_ item: ProgramGroup) -> [String]
    }

    final class ProgramGroupCodeLengthRule: ProgramGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramGroupReviewerLengthRule: ProgramGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramGroup) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramGroupRequiredCodeRule: ProgramGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a program group.
    final class ProgramGroupValidator {
        var rules: [any ProgramGroupRule]

        init(rules: [any ProgramGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramGroup) -> [String] {
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

        func requireValid(_ item: ProgramGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramGroup]) -> [String: [String]] {
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

    static func defaultProgramGroupValidator() -> ProgramGroupValidator {
        return ProgramGroupValidator(
            rules: [
                ProgramGroupCodeLengthRule(maxLength: 86400),
                ProgramGroupReviewerLengthRule(maxLength: 255),
                ProgramGroupRequiredCodeRule(message: "program group needs a value"),
            ]
        )
    }
}
