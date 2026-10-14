import AcmePlatform
import Foundation

extension Labs {
    /// A rule a global accession digest must pass. Check returns its problems, or none.
    protocol GlobalAccessionDigestRule {
        func check(_ item: GlobalAccessionDigest) -> [String]
    }

    final class GlobalAccessionDigestRequiredNameRule: GlobalAccessionDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalAccessionDigest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalAccessionDigestCodePrefixRule: GlobalAccessionDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalAccessionDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalAccessionDigestLocaleLengthRule: GlobalAccessionDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalAccessionDigest) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalAccessionDigestRequiredLocaleRule: GlobalAccessionDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalAccessionDigest) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalAccessionDigestNameLengthRule: GlobalAccessionDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalAccessionDigest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalAccessionDigestAllowedLocaleRule: GlobalAccessionDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalAccessionDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.locale)) {
                return ["locale \(item.locale) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a global accession digest.
    final class GlobalAccessionDigestValidator {
        var rules: [any GlobalAccessionDigestRule]

        init(rules: [any GlobalAccessionDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalAccessionDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalAccessionDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalAccessionDigest]) -> [String: [String]] {
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

    static func defaultGlobalAccessionDigestValidator() -> GlobalAccessionDigestValidator {
        return GlobalAccessionDigestValidator(
            rules: [
                GlobalAccessionDigestRequiredNameRule(message: "global accession digest needs this field"),
                GlobalAccessionDigestCodePrefixRule(prefix: "ACM"),
                GlobalAccessionDigestLocaleLengthRule(maxLength: 1000),
                GlobalAccessionDigestRequiredLocaleRule(message: "global accession digest needs an entry"),
                GlobalAccessionDigestNameLengthRule(maxLength: 120),
                GlobalAccessionDigestAllowedLocaleRule(allowed: []),
            ]
        )
    }
}
