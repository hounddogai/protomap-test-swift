import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction group must pass. Check returns its problems, or none.
    protocol InteractionGroupRule {
        func check(_ item: InteractionGroup) -> [String]
    }

    final class InteractionGroupRequiredRegionRule: InteractionGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionGroup) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionGroupRequiredLocaleRule: InteractionGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionGroup) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionGroupRequiredLabelRule: InteractionGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionGroup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a interaction group.
    final class InteractionGroupValidator {
        var rules: [any InteractionGroupRule]

        init(rules: [any InteractionGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InteractionGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionGroup]) -> [String: [String]] {
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

    static func defaultInteractionGroupValidator() -> InteractionGroupValidator {
        return InteractionGroupValidator(
            rules: [
                InteractionGroupRequiredRegionRule(message: "interaction group needs a value"),
                InteractionGroupRequiredLocaleRule(message: "interaction group needs a value"),
                InteractionGroupRequiredLabelRule(message: "interaction group needs this field"),
            ]
        )
    }
}
