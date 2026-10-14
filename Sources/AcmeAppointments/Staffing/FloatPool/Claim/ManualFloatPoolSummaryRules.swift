import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a manual float pool summary must pass. Check returns its problems, or none.
    protocol ManualFloatPoolSummaryRule {
        func check(_ item: ManualFloatPoolSummary) -> [String]
    }

    final class ManualFloatPoolSummaryNameLengthRule: ManualFloatPoolSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualFloatPoolSummary) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualFloatPoolSummaryCodeLengthRule: ManualFloatPoolSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualFloatPoolSummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualFloatPoolSummaryRequiredNameRule: ManualFloatPoolSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualFloatPoolSummary) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual float pool summary.
    final class ManualFloatPoolSummaryValidator {
        var rules: [any ManualFloatPoolSummaryRule]

        init(rules: [any ManualFloatPoolSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualFloatPoolSummary) -> [String] {
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

        func requireValid(_ item: ManualFloatPoolSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualFloatPoolSummary]) -> [String: [String]] {
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

    static func defaultManualFloatPoolSummaryValidator() -> ManualFloatPoolSummaryValidator {
        return ManualFloatPoolSummaryValidator(
            rules: [
                ManualFloatPoolSummaryNameLengthRule(maxLength: 86400),
                ManualFloatPoolSummaryCodeLengthRule(maxLength: 16),
                ManualFloatPoolSummaryRequiredNameRule(message: "manual float pool summary needs an entry"),
            ]
        )
    }
}
