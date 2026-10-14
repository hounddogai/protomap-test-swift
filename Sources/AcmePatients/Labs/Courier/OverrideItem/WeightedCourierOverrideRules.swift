import AcmePlatform
import Foundation

extension Labs {
    /// A rule a weighted courier override must pass. Check returns its problems, or none.
    protocol WeightedCourierOverrideRule {
        func check(_ item: WeightedCourierOverride) -> [String]
    }

    final class WeightedCourierOverrideCodeLengthRule: WeightedCourierOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedCourierOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedCourierOverrideRequiredContactEmailRule: WeightedCourierOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedCourierOverride) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedCourierOverrideContactEmailLengthRule: WeightedCourierOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedCourierOverride) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted courier override.
    final class WeightedCourierOverrideValidator {
        var rules: [any WeightedCourierOverrideRule]

        init(rules: [any WeightedCourierOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedCourierOverride) -> [String] {
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

        func requireValid(_ item: WeightedCourierOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedCourierOverride]) -> [String: [String]] {
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

    static func defaultWeightedCourierOverrideValidator() -> WeightedCourierOverrideValidator {
        return WeightedCourierOverrideValidator(
            rules: [
                WeightedCourierOverrideCodeLengthRule(maxLength: 64),
                WeightedCourierOverrideRequiredContactEmailRule(message: "weighted courier override needs this field"),
                WeightedCourierOverrideContactEmailLengthRule(maxLength: 3600),
            ]
        )
    }
}
