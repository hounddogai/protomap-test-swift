import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read rule must pass. Check returns its problems, or none.
    protocol ReadRuleRule {
        func check(_ item: ReadRule) -> [String]
    }

    final class ReadRuleRequiredNameRule: ReadRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadRule) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadRuleNameLengthRule: ReadRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadRule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadRuleCodeLengthRule: ReadRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReadRuleRequiredCodeRule: ReadRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadRuleRequiredDiagnosisCodeRule: ReadRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadRule) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a read rule.
    final class ReadRuleValidator {
        var rules: [any ReadRuleRule]

        init(rules: [any ReadRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReadRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadRule]) -> [String: [String]] {
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

    static func defaultReadRuleValidator() -> ReadRuleValidator {
        return ReadRuleValidator(
            rules: [
                ReadRuleRequiredNameRule(message: "read rule needs this field"),
                ReadRuleNameLengthRule(maxLength: 80),
                ReadRuleCodeLengthRule(maxLength: 64),
                ReadRuleRequiredCodeRule(message: "read rule needs this field"),
                ReadRuleRequiredDiagnosisCodeRule(message: "read rule needs this field"),
            ]
        )
    }
}
