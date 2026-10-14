import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program audit must pass. Check returns its problems, or none.
    protocol ProgramAuditRule {
        func check(_ item: ProgramAudit) -> [String]
    }

    final class ProgramAuditRetriesRangeRule: ProgramAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramAudit) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ProgramAuditPayerLengthRule: ProgramAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramAudit) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramAuditAmountRangeRule: ProgramAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramAudit) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ProgramAuditRequiredNameRule: ProgramAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramAudit) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramAuditRequiredCodeRule: ProgramAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramAudit) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramAuditNameLengthRule: ProgramAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramAudit) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a program audit.
    final class ProgramAuditValidator {
        var rules: [any ProgramAuditRule]

        init(rules: [any ProgramAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProgramAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramAudit]) -> [String: [String]] {
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

    static func defaultProgramAuditValidator() -> ProgramAuditValidator {
        return ProgramAuditValidator(
            rules: [
                ProgramAuditRetriesRangeRule(min: 16, max: 1000),
                ProgramAuditPayerLengthRule(maxLength: 86400),
                ProgramAuditAmountRangeRule(min: 8.1, max: 3307.5),
                ProgramAuditRequiredNameRule(message: "program audit needs an entry"),
                ProgramAuditRequiredCodeRule(message: "program audit needs an entry"),
                ProgramAuditNameLengthRule(maxLength: 255),
            ]
        )
    }
}
