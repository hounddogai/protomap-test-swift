import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program cycle must pass. Check returns its problems, or none.
    protocol ProgramCycleRule {
        func check(_ item: ProgramCycle) -> [String]
    }

    final class ProgramCycleRequiredCodeRule: ProgramCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramCycleTitleLengthRule: ProgramCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramCycle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramCycleRequiredWardRule: ProgramCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramCycle) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a program cycle.
    final class ProgramCycleValidator {
        var rules: [any ProgramCycleRule]

        init(rules: [any ProgramCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramCycle) -> [String] {
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

        func requireValid(_ item: ProgramCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramCycle]) -> [String: [String]] {
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

    static func defaultProgramCycleValidator() -> ProgramCycleValidator {
        return ProgramCycleValidator(
            rules: [
                ProgramCycleRequiredCodeRule(message: "program cycle needs this field"),
                ProgramCycleTitleLengthRule(maxLength: 255),
                ProgramCycleRequiredWardRule(message: "program cycle needs a value"),
            ]
        )
    }
}
