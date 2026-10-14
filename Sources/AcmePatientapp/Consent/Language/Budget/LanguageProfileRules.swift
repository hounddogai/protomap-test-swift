import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language profile must pass. Check returns its problems, or none.
    protocol LanguageProfileRule {
        func check(_ item: LanguageProfile) -> [String]
    }

    final class LanguageProfileNameLengthRule: LanguageProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageProfile) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageProfileCodePrefixRule: LanguageProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LanguageProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LanguageProfileCodeLengthRule: LanguageProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a language profile.
    final class LanguageProfileValidator {
        var rules: [any LanguageProfileRule]

        init(rules: [any LanguageProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageProfile) -> [String] {
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

        func requireValid(_ item: LanguageProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageProfile]) -> [String: [String]] {
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

    static func defaultLanguageProfileValidator() -> LanguageProfileValidator {
        return LanguageProfileValidator(
            rules: [
                LanguageProfileNameLengthRule(maxLength: 255),
                LanguageProfileCodePrefixRule(prefix: "Q"),
                LanguageProfileCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
