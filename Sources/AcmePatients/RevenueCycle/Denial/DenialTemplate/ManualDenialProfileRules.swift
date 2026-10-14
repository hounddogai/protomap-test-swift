import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a manual denial profile must pass. Check returns its problems, or none.
    protocol ManualDenialProfileRule {
        func check(_ item: ManualDenialProfile) -> [String]
    }

    final class ManualDenialProfileRequiredExternalRefRule: ManualDenialProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualDenialProfile) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualDenialProfileCodePrefixRule: ManualDenialProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualDenialProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualDenialProfileCodeLengthRule: ManualDenialProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualDenialProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualDenialProfileAllowedExternalRefRule: ManualDenialProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualDenialProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is duplicated"]
            }
            return []
        }
    }

    final class ManualDenialProfileRequiredTitleRule: ManualDenialProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualDenialProfile) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualDenialProfileTitleLengthRule: ManualDenialProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualDenialProfile) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual denial profile.
    final class ManualDenialProfileValidator {
        var rules: [any ManualDenialProfileRule]

        init(rules: [any ManualDenialProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualDenialProfile) -> [String] {
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

        func requireValid(_ item: ManualDenialProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualDenialProfile]) -> [String: [String]] {
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

    static func defaultManualDenialProfileValidator() -> ManualDenialProfileValidator {
        return ManualDenialProfileValidator(
            rules: [
                ManualDenialProfileRequiredExternalRefRule(message: "manual denial profile needs an entry"),
                ManualDenialProfileCodePrefixRule(prefix: "OPS"),
                ManualDenialProfileCodeLengthRule(maxLength: 1000),
                ManualDenialProfileAllowedExternalRefRule(allowed: ["seasonal", "seasonal"]),
                ManualDenialProfileRequiredTitleRule(message: "manual denial profile needs a value"),
                ManualDenialProfileTitleLengthRule(maxLength: 32),
            ]
        )
    }
}
