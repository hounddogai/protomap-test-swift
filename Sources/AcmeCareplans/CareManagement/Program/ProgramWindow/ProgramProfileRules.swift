import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program profile must pass. Check returns its problems, or none.
    protocol ProgramProfileRule {
        func check(_ item: ProgramProfile) -> [String]
    }

    final class ProgramProfileLabelLengthRule: ProgramProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramProfile) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramProfileRequiredExternalRefRule: ProgramProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramProfile) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramProfileRequiredProcedureCodeRule: ProgramProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramProfile) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramProfileRequiredCodeRule: ProgramProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramProfileAllowedExternalRefRule: ProgramProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProgramProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is too long"]
            }
            return []
        }
    }

    final class ProgramProfileExternalRefLengthRule: ProgramProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramProfile) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a program profile.
    final class ProgramProfileValidator {
        var rules: [any ProgramProfileRule]

        init(rules: [any ProgramProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramProfile) -> [String] {
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

        func requireValid(_ item: ProgramProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramProfile]) -> [String: [String]] {
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

    static func defaultProgramProfileValidator() -> ProgramProfileValidator {
        return ProgramProfileValidator(
            rules: [
                ProgramProfileLabelLengthRule(maxLength: 120),
                ProgramProfileRequiredExternalRefRule(message: "program profile needs this field"),
                ProgramProfileRequiredProcedureCodeRule(message: "program profile needs this field"),
                ProgramProfileRequiredCodeRule(message: "program profile needs an entry"),
                ProgramProfileAllowedExternalRefRule(allowed: ["strict"]),
                ProgramProfileExternalRefLengthRule(maxLength: 16),
            ]
        )
    }
}
