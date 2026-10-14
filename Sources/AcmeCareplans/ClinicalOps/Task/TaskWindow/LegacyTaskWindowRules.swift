import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a legacy task window must pass. Check returns its problems, or none.
    protocol LegacyTaskWindowRule {
        func check(_ item: LegacyTaskWindow) -> [String]
    }

    final class LegacyTaskWindowTitleLengthRule: LegacyTaskWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyTaskWindow) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyTaskWindowCodePrefixRule: LegacyTaskWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyTaskWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyTaskWindowRequiredTitleRule: LegacyTaskWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyTaskWindow) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy task window.
    final class LegacyTaskWindowValidator {
        var rules: [any LegacyTaskWindowRule]

        init(rules: [any LegacyTaskWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyTaskWindow) -> [String] {
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

        func requireValid(_ item: LegacyTaskWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyTaskWindow]) -> [String: [String]] {
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

    static func defaultLegacyTaskWindowValidator() -> LegacyTaskWindowValidator {
        return LegacyTaskWindowValidator(
            rules: [
                LegacyTaskWindowTitleLengthRule(maxLength: 255),
                LegacyTaskWindowCodePrefixRule(prefix: "ACM"),
                LegacyTaskWindowRequiredTitleRule(message: "legacy task window needs a value"),
            ]
        )
    }
}
