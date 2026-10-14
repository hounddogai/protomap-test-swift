import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language digest must pass. Check returns its problems, or none.
    protocol LanguageDigestRule {
        func check(_ item: LanguageDigest) -> [String]
    }

    final class LanguageDigestChecksumLengthRule: LanguageDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageDigest) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageDigestAllowedChecksumRule: LanguageDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LanguageDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is too long"]
            }
            return []
        }
    }

    final class LanguageDigestRevisionRangeRule: LanguageDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageDigest) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LanguageDigestCodePrefixRule: LanguageDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LanguageDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a language digest.
    final class LanguageDigestValidator {
        var rules: [any LanguageDigestRule]

        init(rules: [any LanguageDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LanguageDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageDigest]) -> [String: [String]] {
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

    static func defaultLanguageDigestValidator() -> LanguageDigestValidator {
        return LanguageDigestValidator(
            rules: [
                LanguageDigestChecksumLengthRule(maxLength: 80),
                LanguageDigestAllowedChecksumRule(allowed: ["rolling", "seasonal", "lenient"]),
                LanguageDigestRevisionRangeRule(min: 16, max: 80),
                LanguageDigestCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
