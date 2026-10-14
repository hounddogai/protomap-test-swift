import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality group must pass. Check returns its problems, or none.
    protocol ModalityGroupRule {
        func check(_ item: ModalityGroup) -> [String]
    }

    final class ModalityGroupCodePrefixRule: ModalityGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ModalityGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ModalityGroupRequiredLabelRule: ModalityGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityGroup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityGroupBedLengthRule: ModalityGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityGroup) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityGroupCodeLengthRule: ModalityGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityGroupRequiredBedRule: ModalityGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityGroup) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a modality group.
    final class ModalityGroupValidator {
        var rules: [any ModalityGroupRule]

        init(rules: [any ModalityGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ModalityGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityGroup]) -> [String: [String]] {
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

    static func defaultModalityGroupValidator() -> ModalityGroupValidator {
        return ModalityGroupValidator(
            rules: [
                ModalityGroupCodePrefixRule(prefix: "ACM"),
                ModalityGroupRequiredLabelRule(message: "modality group needs a value"),
                ModalityGroupBedLengthRule(maxLength: 255),
                ModalityGroupCodeLengthRule(maxLength: 120),
                ModalityGroupRequiredBedRule(message: "modality group needs this field"),
            ]
        )
    }
}
