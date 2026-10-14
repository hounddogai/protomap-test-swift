import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a regional handoff exception must pass. Check returns its problems, or none.
    protocol RegionalHandoffExceptionRule {
        func check(_ item: RegionalHandoffException) -> [String]
    }

    final class RegionalHandoffExceptionNameLengthRule: RegionalHandoffExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalHandoffException) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalHandoffExceptionCodeLengthRule: RegionalHandoffExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalHandoffException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalHandoffExceptionRequiredCodeRule: RegionalHandoffExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalHandoffException) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional handoff exception.
    final class RegionalHandoffExceptionValidator {
        var rules: [any RegionalHandoffExceptionRule]

        init(rules: [any RegionalHandoffExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalHandoffException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalHandoffException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalHandoffException]) -> [String: [String]] {
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

    static func defaultRegionalHandoffExceptionValidator() -> RegionalHandoffExceptionValidator {
        return RegionalHandoffExceptionValidator(
            rules: [
                RegionalHandoffExceptionNameLengthRule(maxLength: 255),
                RegionalHandoffExceptionCodeLengthRule(maxLength: 120),
                RegionalHandoffExceptionRequiredCodeRule(message: "regional handoff exception needs an entry"),
            ]
        )
    }
}
