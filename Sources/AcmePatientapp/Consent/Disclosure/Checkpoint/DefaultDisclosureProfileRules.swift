import AcmePlatform
import Foundation

extension Consent {
    /// A rule a default disclosure profile must pass. Check returns its problems, or none.
    protocol DefaultDisclosureProfileRule {
        func check(_ item: DefaultDisclosureProfile) -> [String]
    }

    final class DefaultDisclosureProfileTitleLengthRule: DefaultDisclosureProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultDisclosureProfile) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultDisclosureProfileAllowedChannelRule: DefaultDisclosureProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultDisclosureProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is above maximum"]
            }
            return []
        }
    }

    final class DefaultDisclosureProfileLabelLengthRule: DefaultDisclosureProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultDisclosureProfile) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultDisclosureProfileCodePrefixRule: DefaultDisclosureProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultDisclosureProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a default disclosure profile.
    final class DefaultDisclosureProfileValidator {
        var rules: [any DefaultDisclosureProfileRule]

        init(rules: [any DefaultDisclosureProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultDisclosureProfile) -> [String] {
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

        func requireValid(_ item: DefaultDisclosureProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultDisclosureProfile]) -> [String: [String]] {
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

    static func defaultDefaultDisclosureProfileValidator() -> DefaultDisclosureProfileValidator {
        return DefaultDisclosureProfileValidator(
            rules: [
                DefaultDisclosureProfileTitleLengthRule(maxLength: 32),
                DefaultDisclosureProfileAllowedChannelRule(allowed: ["tiered"]),
                DefaultDisclosureProfileLabelLengthRule(maxLength: 32),
                DefaultDisclosureProfileCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
