import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution adjustment must pass. Check returns its problems, or none.
    protocol SubstitutionAdjustmentRule {
        func check(_ item: SubstitutionAdjustment) -> [String]
    }

    final class SubstitutionAdjustmentRequiredTitleRule: SubstitutionAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionAdjustment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionAdjustmentRequiredContactEmailRule: SubstitutionAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionAdjustment) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionAdjustmentTitleLengthRule: SubstitutionAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionAdjustment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionAdjustmentCodePrefixRule: SubstitutionAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SubstitutionAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SubstitutionAdjustmentContactEmailLengthRule: SubstitutionAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionAdjustment) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a substitution adjustment.
    final class SubstitutionAdjustmentValidator {
        var rules: [any SubstitutionAdjustmentRule]

        init(rules: [any SubstitutionAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SubstitutionAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionAdjustment]) -> [String: [String]] {
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

    static func defaultSubstitutionAdjustmentValidator() -> SubstitutionAdjustmentValidator {
        return SubstitutionAdjustmentValidator(
            rules: [
                SubstitutionAdjustmentRequiredTitleRule(message: "substitution adjustment needs this field"),
                SubstitutionAdjustmentRequiredContactEmailRule(message: "substitution adjustment needs this field"),
                SubstitutionAdjustmentTitleLengthRule(maxLength: 80),
                SubstitutionAdjustmentCodePrefixRule(prefix: "ACM"),
                SubstitutionAdjustmentContactEmailLengthRule(maxLength: 86400),
            ]
        )
    }
}
