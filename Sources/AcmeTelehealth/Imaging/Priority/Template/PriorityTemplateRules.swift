import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a priority template must pass. Check returns its problems, or none.
    protocol PriorityTemplateRule {
        func check(_ item: PriorityTemplate) -> [String]
    }

    final class PriorityTemplateCodePrefixRule: PriorityTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PriorityTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PriorityTemplateAllowedLabelRule: PriorityTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PriorityTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is blocked"]
            }
            return []
        }
    }

    final class PriorityTemplatePhoneLengthRule: PriorityTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityTemplate) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityTemplateRequiredPhoneRule: PriorityTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityTemplate) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PriorityTemplateSourceLengthRule: PriorityTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PriorityTemplate) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PriorityTemplateRequiredLabelRule: PriorityTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PriorityTemplate) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a priority template.
    final class PriorityTemplateValidator {
        var rules: [any PriorityTemplateRule]

        init(rules: [any PriorityTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: PriorityTemplate) -> [String] {
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

        func requireValid(_ item: PriorityTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PriorityTemplate]) -> [String: [String]] {
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

    static func defaultPriorityTemplateValidator() -> PriorityTemplateValidator {
        return PriorityTemplateValidator(
            rules: [
                PriorityTemplateCodePrefixRule(prefix: "X"),
                PriorityTemplateAllowedLabelRule(allowed: ["manual"]),
                PriorityTemplatePhoneLengthRule(maxLength: 86400),
                PriorityTemplateRequiredPhoneRule(message: "priority template needs an entry"),
                PriorityTemplateSourceLengthRule(maxLength: 86400),
                PriorityTemplateRequiredLabelRule(message: "priority template needs an entry"),
            ]
        )
    }
}
