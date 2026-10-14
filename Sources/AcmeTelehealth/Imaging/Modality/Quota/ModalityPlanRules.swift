import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality plan must pass. Check returns its problems, or none.
    protocol ModalityPlanRule {
        func check(_ item: ModalityPlan) -> [String]
    }

    final class ModalityPlanCodeLengthRule: ModalityPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityPlanRequiredBedRule: ModalityPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityPlan) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityPlanCodePrefixRule: ModalityPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ModalityPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ModalityPlanTimezoneLengthRule: ModalityPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityPlan) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a modality plan.
    final class ModalityPlanValidator {
        var rules: [any ModalityPlanRule]

        init(rules: [any ModalityPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ModalityPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityPlan]) -> [String: [String]] {
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

    static func defaultModalityPlanValidator() -> ModalityPlanValidator {
        return ModalityPlanValidator(
            rules: [
                ModalityPlanCodeLengthRule(maxLength: 16),
                ModalityPlanRequiredBedRule(message: "modality plan needs a value"),
                ModalityPlanCodePrefixRule(prefix: "Q"),
                ModalityPlanTimezoneLengthRule(maxLength: 64),
            ]
        )
    }
}
