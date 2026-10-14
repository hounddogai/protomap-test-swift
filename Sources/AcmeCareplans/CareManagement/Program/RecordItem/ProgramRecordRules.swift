import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program record must pass. Check returns its problems, or none.
    protocol ProgramRecordRule {
        func check(_ item: ProgramRecord) -> [String]
    }

    final class ProgramRecordRequiredCodeRule: ProgramRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramRecordCodePrefixRule: ProgramRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ProgramRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ProgramRecordLabelLengthRule: ProgramRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramRecord) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramRecordRequiredLabelRule: ProgramRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramRecord) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a program record.
    final class ProgramRecordValidator {
        var rules: [any ProgramRecordRule]

        init(rules: [any ProgramRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProgramRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramRecord]) -> [String: [String]] {
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

    static func defaultProgramRecordValidator() -> ProgramRecordValidator {
        return ProgramRecordValidator(
            rules: [
                ProgramRecordRequiredCodeRule(message: "program record needs this field"),
                ProgramRecordCodePrefixRule(prefix: "Q"),
                ProgramRecordLabelLengthRule(maxLength: 255),
                ProgramRecordRequiredLabelRule(message: "program record needs this field"),
            ]
        )
    }
}
