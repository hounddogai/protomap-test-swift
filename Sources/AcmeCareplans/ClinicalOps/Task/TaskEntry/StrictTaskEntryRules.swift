import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a strict task entry must pass. Check returns its problems, or none.
    protocol StrictTaskEntryRule {
        func check(_ item: StrictTaskEntry) -> [String]
    }

    final class StrictTaskEntryAllowedProcedureCodeRule: StrictTaskEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictTaskEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is not allowed"]
            }
            return []
        }
    }

    final class StrictTaskEntryRequiredProcedureCodeRule: StrictTaskEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictTaskEntry) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictTaskEntryCodeLengthRule: StrictTaskEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictTaskEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict task entry.
    final class StrictTaskEntryValidator {
        var rules: [any StrictTaskEntryRule]

        init(rules: [any StrictTaskEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictTaskEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictTaskEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictTaskEntry]) -> [String: [String]] {
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

    static func defaultStrictTaskEntryValidator() -> StrictTaskEntryValidator {
        return StrictTaskEntryValidator(
            rules: [
                StrictTaskEntryAllowedProcedureCodeRule(allowed: ["scheduled", "global", "weighted"]),
                StrictTaskEntryRequiredProcedureCodeRule(message: "strict task entry needs a value"),
                StrictTaskEntryCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
