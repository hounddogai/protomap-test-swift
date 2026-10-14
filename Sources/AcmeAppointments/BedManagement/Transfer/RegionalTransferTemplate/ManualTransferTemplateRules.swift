import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a manual transfer template must pass. Check returns its problems, or none.
    protocol ManualTransferTemplateRule {
        func check(_ item: ManualTransferTemplate) -> [String]
    }

    final class ManualTransferTemplateReviewerLengthRule: ManualTransferTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualTransferTemplate) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualTransferTemplateCodePrefixRule: ManualTransferTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualTransferTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualTransferTemplateTitleLengthRule: ManualTransferTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualTransferTemplate) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual transfer template.
    final class ManualTransferTemplateValidator {
        var rules: [any ManualTransferTemplateRule]

        init(rules: [any ManualTransferTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualTransferTemplate) -> [String] {
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

        func requireValid(_ item: ManualTransferTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualTransferTemplate]) -> [String: [String]] {
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

    static func defaultManualTransferTemplateValidator() -> ManualTransferTemplateValidator {
        return ManualTransferTemplateValidator(
            rules: [
                ManualTransferTemplateReviewerLengthRule(maxLength: 255),
                ManualTransferTemplateCodePrefixRule(prefix: "X"),
                ManualTransferTemplateTitleLengthRule(maxLength: 16),
            ]
        )
    }
}
