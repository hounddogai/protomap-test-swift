import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a manual risk score group must pass. Check returns its problems, or none.
    protocol ManualRiskScoreGroupRule {
        func check(_ item: ManualRiskScoreGroup) -> [String]
    }

    final class ManualRiskScoreGroupRequiredCodeRule: ManualRiskScoreGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRiskScoreGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualRiskScoreGroupRequiredDescriptionRule: ManualRiskScoreGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualRiskScoreGroup) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualRiskScoreGroupDescriptionLengthRule: ManualRiskScoreGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRiskScoreGroup) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual risk score group.
    final class ManualRiskScoreGroupValidator {
        var rules: [any ManualRiskScoreGroupRule]

        init(rules: [any ManualRiskScoreGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualRiskScoreGroup) -> [String] {
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

        func requireValid(_ item: ManualRiskScoreGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualRiskScoreGroup]) -> [String: [String]] {
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

    static func defaultManualRiskScoreGroupValidator() -> ManualRiskScoreGroupValidator {
        return ManualRiskScoreGroupValidator(
            rules: [
                ManualRiskScoreGroupRequiredCodeRule(message: "manual risk score group needs this field"),
                ManualRiskScoreGroupRequiredDescriptionRule(message: "manual risk score group needs this field"),
                ManualRiskScoreGroupDescriptionLengthRule(maxLength: 86400),
            ]
        )
    }
}
