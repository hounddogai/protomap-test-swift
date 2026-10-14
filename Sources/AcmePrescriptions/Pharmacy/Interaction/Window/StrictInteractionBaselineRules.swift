import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a strict interaction baseline must pass. Check returns its problems, or none.
    protocol StrictInteractionBaselineRule {
        func check(_ item: StrictInteractionBaseline) -> [String]
    }

    final class StrictInteractionBaselineRequiredCodeRule: StrictInteractionBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictInteractionBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictInteractionBaselineCategoryLengthRule: StrictInteractionBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictInteractionBaseline) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictInteractionBaselineAllowedCodeRule: StrictInteractionBaselineRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictInteractionBaseline) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    final class StrictInteractionBaselineLabelLengthRule: StrictInteractionBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictInteractionBaseline) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictInteractionBaselineRequiredTitleRule: StrictInteractionBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictInteractionBaseline) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict interaction baseline.
    final class StrictInteractionBaselineValidator {
        var rules: [any StrictInteractionBaselineRule]

        init(rules: [any StrictInteractionBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictInteractionBaseline) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictInteractionBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictInteractionBaseline]) -> [String: [String]] {
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

    static func defaultStrictInteractionBaselineValidator() -> StrictInteractionBaselineValidator {
        return StrictInteractionBaselineValidator(
            rules: [
                StrictInteractionBaselineRequiredCodeRule(message: "strict interaction baseline needs a value"),
                StrictInteractionBaselineCategoryLengthRule(maxLength: 255),
                StrictInteractionBaselineAllowedCodeRule(allowed: []),
                StrictInteractionBaselineLabelLengthRule(maxLength: 120),
                StrictInteractionBaselineRequiredTitleRule(message: "strict interaction baseline needs this field"),
            ]
        )
    }
}
