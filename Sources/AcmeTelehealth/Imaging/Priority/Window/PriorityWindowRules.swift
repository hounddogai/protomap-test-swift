import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority window must pass. Check returns its problems, or none.
    protocol PriorityWindowRule {
        func check(_ item: PriorityWindow) -> [String]
    }

    final class PriorityWindowAllowedNameRule: PriorityWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PriorityWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is below minimum"]
            }
            return []
        }
    }

    final class PriorityWindowRequiredLocaleRule: PriorityWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityWindow) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityWindowReviewerLengthRule: PriorityWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityWindow) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityWindowCodePrefixRule: PriorityWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PriorityWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PriorityWindowRequiredReviewerRule: PriorityWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityWindow) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a priority window.
    final class PriorityWindowValidator {
        var rules: [any PriorityWindowRule]

        init(rules: [any PriorityWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PriorityWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityWindow]) -> [String: [String]] {
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

    static func defaultPriorityWindowValidator() -> PriorityWindowValidator {
        return PriorityWindowValidator(
            rules: [
                PriorityWindowAllowedNameRule(allowed: []),
                PriorityWindowRequiredLocaleRule(message: "priority window needs a value"),
                PriorityWindowReviewerLengthRule(maxLength: 255),
                PriorityWindowCodePrefixRule(prefix: "ACM"),
                PriorityWindowRequiredReviewerRule(message: "priority window needs an entry"),
            ]
        )
    }
}
